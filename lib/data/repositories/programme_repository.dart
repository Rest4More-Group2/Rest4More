import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/enums.dart';
import '../database/local_types.dart';
import 'profile_repository.dart';
import 'repository_support.dart';

/// Er loopt al een programma (actief of gepauzeerd).
class AlreadyEnrolledError implements Exception {
  const AlreadyEnrolledError();

  @override
  String toString() => 'AlreadyEnrolledError';
}

/// Handeling die in de huidige status niet past.
class ProgrammeStateError implements Exception {
  const ProgrammeStateError(this.message);

  final String message;

  @override
  String toString() => 'ProgrammeStateError: $message';
}

/// Beginwaarden voor een dag bij het aanmaken.
class DaySeed {
  const DaySeed({
    required this.dayNumber,
    required this.contentId,
    required this.scheduledFor,
    this.size = DaySize.standard,
    this.snapshot = const {},
  });

  /// 1 tot en met 14.
  final int dayNumber;
  final String contentId;

  /// Lokale kalenderdatum.
  final DateTime scheduledFor;
  final DaySize size;
  final Map<String, dynamic> snapshot;
}

/// Programma van 14 dagen. Een latere status wordt nooit teruggezet door een
/// eerdere gebeurtenis: een dag openen maakt hem nooit af.
class ProgrammeRepository {
  ProgrammeRepository(this._db, {this._now = DateTime.now});

  final AppDatabase _db;
  final Clock _now;

  DateTime get _stamp => _now().toUtc();

  static const _live = {EnrollmentStatus.active, EnrollmentStatus.paused};

  /// Volgt de lopende deelname (actief of gepauzeerd).
  Stream<ProgrammeEnrollment?> watchActiveEnrollment() =>
      (_db.select(_db.programmeEnrollments)
            ..where((t) =>
                t.status.isIn(_live.map((s) => s.id)) & t.deletedAt.isNull())
            ..limit(1))
          .watchSingleOrNull();

  Stream<List<ProgrammeDay>> watchDays(String enrollmentId) =>
      (_db.select(_db.programmeDays)
            ..where((t) =>
                t.enrollmentId.equals(enrollmentId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.dayNumber)]))
          .watch();

  Future<ProgrammeEnrollment> enroll({
    required String contentVersion,
    required Map<String, dynamic> selection,
    required DateTime startedOn,
  }) {
    return _db.transaction(() async {
      final live = await (_db.select(_db.programmeEnrollments)
            ..where((t) =>
                t.status.isIn(_live.map((s) => s.id)) & t.deletedAt.isNull())
            ..limit(1))
          .getSingleOrNull();
      if (live != null) throw const AlreadyEnrolledError();
      final profile = await ProfileRepository(_db, now: _now).get();
      return _db.into(_db.programmeEnrollments).insertReturning(
            ProgrammeEnrollmentsCompanion.insert(
              profileId: profile.id,
              contentVersion: contentVersion,
              startedOn: LocalDate.format(startedOn),
              updatedAt: _stamp,
              selection: Value(selection),
            ),
          );
    });
  }

  Future<void> createDays(String enrollmentId, List<DaySeed> seeds) async {
    for (final seed in seeds) {
      if (seed.dayNumber < 1 || seed.dayNumber > 14) {
        throw InvalidValueError('dayNumber moet 1 tot 14 zijn: ${seed.dayNumber}');
      }
    }
    await _db.transaction(() async {
      final now = _stamp;
      await _db.batch((batch) {
        batch.insertAll(_db.programmeDays, [
          for (final seed in seeds)
            ProgrammeDaysCompanion.insert(
              enrollmentId: enrollmentId,
              dayNumber: seed.dayNumber,
              contentId: seed.contentId,
              scheduledFor: LocalDate.format(seed.scheduledFor),
              updatedAt: now,
              size: Value(seed.size),
              snapshot: Value(seed.snapshot),
            ),
        ]);
      });
    });
  }

  Future<ProgrammeDay> _loadDay(String id) async {
    final row = await (_db.select(_db.programmeDays)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    if (row == null) throw RowNotFoundError('programme_days', id);
    return row;
  }

  Future<void> _writeDay(String id, ProgrammeDaysCompanion changes) =>
      (_db.update(_db.programmeDays)..where((t) => t.id.equals(id))).write(
        changes.copyWith(updatedAt: Value(_stamp), dirty: const Value(true)),
      );

  static int _rank(DayStatus status) => switch (status) {
        DayStatus.planned => 0,
        DayStatus.offered => 1,
        DayStatus.opened => 2,
        DayStatus.completed => 3,
        _ => -1,
      };

  /// Vult het tijdstip van [reached] als dat leeg is en verhoogt de status
  /// nooit terug. Overgeslagen of vervangen dagen blijven ongemoeid.
  Future<void> _reach(String dayId, DayStatus reached) {
    return _db.transaction(() async {
      final day = await _loadDay(dayId);
      if (_rank(day.status) < 0) return;
      final now = _stamp;
      final needsStatus = _rank(reached) > _rank(day.status);
      final DateTime? current = switch (reached) {
        DayStatus.offered => day.offeredAt,
        DayStatus.opened => day.openedAt,
        _ => day.completedAt,
      };
      final needsStamp = current == null;
      if (!needsStatus && !needsStamp) return;
      await _writeDay(
        dayId,
        ProgrammeDaysCompanion(
          status: needsStatus ? Value(reached) : const Value.absent(),
          offeredAt: reached == DayStatus.offered && needsStamp
              ? Value(now)
              : const Value.absent(),
          openedAt: reached == DayStatus.opened && needsStamp
              ? Value(now)
              : const Value.absent(),
          completedAt: reached == DayStatus.completed && needsStamp
              ? Value(now)
              : const Value.absent(),
        ),
      );
    });
  }

  Future<void> markOffered(String dayId) => _reach(dayId, DayStatus.offered);

  Future<void> markOpened(String dayId) => _reach(dayId, DayStatus.opened);

  Future<void> markCompleted(String dayId) =>
      _reach(dayId, DayStatus.completed);

  Future<void> setSize(String dayId, DaySize size) async {
    await _loadDay(dayId);
    await _writeDay(dayId, ProgrammeDaysCompanion(size: Value(size)));
  }

  Future<void> skip(String dayId) async {
    final day = await _loadDay(dayId);
    if (day.status == DayStatus.completed) {
      throw const ProgrammeStateError('een afgeronde dag kan niet worden overgeslagen');
    }
    await _writeDay(
      dayId,
      const ProgrammeDaysCompanion(status: Value(DayStatus.skipped)),
    );
  }

  /// Vervangt de inhoud van een dag door andere inhoud.
  Future<void> replace(
    String dayId, {
    required String contentId,
    Map<String, dynamic> snapshot = const {},
  }) async {
    final day = await _loadDay(dayId);
    if (day.status == DayStatus.completed) {
      throw const ProgrammeStateError('een afgeronde dag kan niet worden vervangen');
    }
    await _writeDay(
      dayId,
      ProgrammeDaysCompanion(
        status: const Value(DayStatus.replaced),
        contentId: Value(contentId),
        snapshot: Value(snapshot),
      ),
    );
  }

  /// Bewaart de check-in. Een `blocker` mag alleen bij `partly` of `no`.
  Future<void> recordCheckin(
    String dayId, {
    required DayFit fit,
    DayBlocker? blocker,
  }) async {
    final allowsBlocker = fit == DayFit.partly || fit == DayFit.no;
    if (blocker != null && !allowsBlocker) {
      throw const InvalidValueError('blocker hoort alleen bij fit partly of no');
    }
    await _loadDay(dayId);
    await _writeDay(
      dayId,
      ProgrammeDaysCompanion(fit: Value(fit), blocker: Value(blocker)),
    );
  }

  /// Bewaart de ochtendcheck. `restedScore` is 1 tot en met 5.
  Future<void> recordMorningCheck(
    String dayId, {
    required DayProtected protected,
    int? restedScore,
  }) async {
    if (restedScore != null && (restedScore < 1 || restedScore > 5)) {
      throw InvalidValueError('restedScore moet 1 tot 5 zijn: $restedScore');
    }
    await _loadDay(dayId);
    await _writeDay(
      dayId,
      ProgrammeDaysCompanion(
        protected: Value(protected),
        restedScore: Value(restedScore),
      ),
    );
  }

  Future<ProgrammeEnrollment> _loadEnrollment(String id) async {
    final row = await (_db.select(_db.programmeEnrollments)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    if (row == null) throw RowNotFoundError('programme_enrollments', id);
    return row;
  }

  Future<void> _setStatus(
    String id,
    Set<EnrollmentStatus> allowedFrom,
    EnrollmentStatus to, {
    ProgrammeDirection? direction,
    bool finished = false,
  }) {
    return _db.transaction(() async {
      final enrollment = await _loadEnrollment(id);
      if (!allowedFrom.contains(enrollment.status)) {
        throw ProgrammeStateError(
          'van ${enrollment.status.id} naar ${to.id} kan niet',
        );
      }
      await (_db.update(_db.programmeEnrollments)
            ..where((t) => t.id.equals(id)))
          .write(ProgrammeEnrollmentsCompanion(
        status: Value(to),
        direction: Value.absentIfNull(direction),
        completedAt: finished ? Value(_stamp) : const Value.absent(),
        updatedAt: Value(_stamp),
        dirty: const Value(true),
      ));
    });
  }

  Future<void> pause(String id) => _setStatus(
      id, {EnrollmentStatus.active}, EnrollmentStatus.paused);

  Future<void> resume(String id) => _setStatus(
      id, {EnrollmentStatus.paused}, EnrollmentStatus.active);

  Future<void> complete(String id, ProgrammeDirection direction) => _setStatus(
        id,
        _live,
        EnrollmentStatus.completed,
        direction: direction,
        finished: true,
      );

  Future<void> stop(String id) =>
      _setStatus(id, _live, EnrollmentStatus.stopped);
}
