import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/converters.dart';
import '../database/enums.dart';
import '../database/local_types.dart';
import 'repository_support.dart';

/// Er loopt al een sessie.
class SessionAlreadyOpenError implements Exception {
  const SessionAlreadyOpenError();

  @override
  String toString() => 'SessionAlreadyOpenError';
}

/// Een overgang of handeling die in de huidige toestand niet mag.
class IllegalTransition implements Exception {
  const IllegalTransition(this.from, this.to, [this.message]);

  final SessionState from;
  final SessionState? to;
  final String? message;

  @override
  String toString() => 'IllegalTransition: ${from.id} -> ${to?.id}'
      '${message == null ? '' : ' ($message)'}';
}

/// Toegestane overgangen. Afronden gaat via `finish`, niet via `transition`.
const Map<SessionState, Set<SessionState>> sessionTransitions = {
  SessionState.selecting: {SessionState.awaitingScan, SessionState.completed},
  SessionState.awaitingScan: {SessionState.activating, SessionState.completed},
  SessionState.activating: {SessionState.active, SessionState.completed},
  SessionState.active: {
    SessionState.awaitingUnlock,
    SessionState.emergency,
    SessionState.permissionLost,
    SessionState.releasing,
  },
  SessionState.awaitingUnlock: {SessionState.releasing, SessionState.active},
  SessionState.emergency: {SessionState.releasing},
  SessionState.permissionLost: {SessionState.releasing, SessionState.completed},
  SessionState.releasing: {SessionState.completed},
};

/// Beheert de levensloop van focussessies. Er is nooit meer dan een open
/// sessie.
class FocusSessionRepository {
  FocusSessionRepository(this._db, {this._now = DateTime.now});

  final AppDatabase _db;
  final Clock _now;

  SimpleSelectStatement<$FocusSessionsTable, FocusSession> get _openQuery =>
      _db.select(_db.focusSessions)
        ..where((t) => t.endedAt.isNull() & t.deletedAt.isNull())
        ..limit(1);

  Stream<FocusSession?> watchOpen() => _openQuery.watchSingleOrNull();

  Future<FocusSession?> findOpen() => _openQuery.getSingleOrNull();

  /// Afgeronde sessies, nieuwste eerst.
  Stream<List<FocusSession>> watchHistory({int limit = 50}) =>
      (_db.select(_db.focusSessions)
            ..where((t) => t.endedAt.isNotNull() & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
            ..limit(limit))
          .watch();

  /// Start een sessie in de toestand `selecting`.
  Future<FocusSession> start({
    required String mode,
    required SessionSource source,
    required SessionPlatform platform,
    String? routineId,
    String? blockProfileId,
    String? accessoryId,
    int? plannedSeconds,
  }) {
    return _db.transaction(() async {
      if (await findOpen() != null) throw const SessionAlreadyOpenError();
      final now = _now();
      return _db.into(_db.focusSessions).insertReturning(
            FocusSessionsCompanion.insert(
              mode: mode,
              source: source,
              platform: platform,
              state: SessionState.selecting,
              startedAt: now.toUtc(),
              localDate: LocalDate.format(now.toLocal()),
              updatedAt: now.toUtc(),
              routineId: Value(routineId),
              blockProfileId: Value(blockProfileId),
              accessoryId: Value(accessoryId),
              plannedSeconds: Value(plannedSeconds),
            ),
          );
    });
  }

  Future<FocusSession> _load(String id) async {
    final row = await (_db.select(_db.focusSessions)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    if (row == null) throw RowNotFoundError('focus_sessions', id);
    return row;
  }

  Future<void> _apply(
    FocusSession session,
    FocusSessionsCompanion changes, {
    SessionEventData? event,
  }) {
    return (_db.update(_db.focusSessions)
          ..where((t) => t.id.equals(session.id)))
        .write(changes.copyWith(
      events: event == null
          ? const Value.absent()
          : Value([...session.events, event]),
      updatedAt: Value(_now().toUtc()),
      dirty: const Value(true),
    ));
  }

  /// Gaat naar een volgende toestand en legt de overgang vast in `events`.
  /// Afronden (`completed`) gaat via [finish].
  Future<void> transition(
    String sessionId,
    SessionState to, {
    String? errorCode,
  }) {
    return _db.transaction(() async {
      final session = await _load(sessionId);
      if (to == SessionState.completed) {
        throw IllegalTransition(session.state, to, 'gebruik finish');
      }
      _check(session.state, to);
      await _apply(
        session,
        FocusSessionsCompanion(state: Value(to)),
        event: SessionEventData(
          at: _now().toUtc(),
          event: SessionEventType.transition,
          fromState: session.state,
          toState: to,
          errorCode: errorCode,
        ),
      );
    });
  }

  void _check(SessionState from, SessionState to) {
    if (!(sessionTransitions[from]?.contains(to) ?? false)) {
      throw IllegalTransition(from, to);
    }
  }

  /// Zet `blocking_confirmed_at`. Dit is de enige plek waar dat gebeurt, en
  /// alleen vanuit `activating`: niets anders mag doen alsof blokkeren werkt.
  Future<void> markBlockingConfirmed(String sessionId) {
    return _db.transaction(() async {
      final session = await _load(sessionId);
      if (session.state != SessionState.activating) {
        throw IllegalTransition(
          session.state,
          null,
          'bevestigen kan alleen vanuit activating',
        );
      }
      await _apply(
        session,
        FocusSessionsCompanion(blockingConfirmedAt: Value(_now().toUtc())),
      );
    });
  }

  Future<void> markBlockingReleased(String sessionId) async {
    final session = await _load(sessionId);
    await _apply(
      session,
      FocusSessionsCompanion(blockingReleasedAt: Value(_now().toUtc())),
    );
  }

  /// Rondt de sessie af met een uitkomst. Mag alleen vanuit een toestand die
  /// naar `completed` mag. Bij een mislukte activatie hoort een [errorCode].
  Future<void> finish(
    String sessionId,
    SessionOutcome outcome, {
    SessionFeeling? feeling,
    String? errorCode,
  }) {
    return _db.transaction(() async {
      final session = await _load(sessionId);
      _check(session.state, SessionState.completed);
      final now = _now().toUtc();
      await _apply(
        session,
        FocusSessionsCompanion(
          state: const Value(SessionState.completed),
          endedAt: Value(now),
          outcome: Value(outcome),
          feeling: Value.absentIfNull(feeling),
        ),
        event: SessionEventData(
          at: now,
          event: SessionEventType.transition,
          fromState: session.state,
          toState: SessionState.completed,
          errorCode: errorCode,
        ),
      );
    });
  }
}
