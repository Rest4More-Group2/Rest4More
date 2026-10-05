import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/repositories/programme_repository.dart';
import 'package:rest4more/data/repositories/repository_support.dart';

import 'test_support.dart';

void main() {
  late AppDatabase db;
  late TestClock clock;
  late ProgrammeRepository repo;
  late String enrollmentId;
  late List<ProgrammeDay> days;

  setUp(() async {
    db = memoryDb();
    clock = TestClock();
    repo = ProgrammeRepository(db, now: clock.call);
    enrollmentId = await enrollWithDays(repo);
    days = await repo.watchDays(enrollmentId).first;
  });
  tearDown(() => db.close());

  Future<ProgrammeDay> reload(String id) async =>
      (await repo.watchDays(enrollmentId).first).firstWhere((d) => d.id == id);

  test('veertien dagen in volgorde met status planned', () {
    expect(days, hasLength(14));
    expect(days.map((d) => d.dayNumber), [for (var i = 1; i <= 14; i++) i]);
    expect(days.every((d) => d.status == DayStatus.planned), isTrue);
    expect(days.first.scheduledFor, '2026-03-02');
  });

  test('openen rondt een dag nooit af', () async {
    final day = days.first;
    await repo.markOpened(day.id);
    final opened = await reload(day.id);
    expect(opened.status, DayStatus.opened);
    expect(opened.openedAt, isNotNull);
    expect(opened.completedAt, isNull);
  });

  test('tijdstippen zijn onafhankelijk van elkaar', () async {
    final day = days.first;
    await repo.markOffered(day.id);
    clock.advance(const Duration(minutes: 1));
    await repo.markCompleted(day.id);
    final row = await reload(day.id);
    expect(row.offeredAt, isNotNull);
    expect(row.openedAt, isNull);
    expect(row.completedAt, isNotNull);
    expect(row.status, DayStatus.completed);
  });

  test('een afgeronde dag wordt niet teruggezet', () async {
    final day = days.first;
    await repo.markCompleted(day.id);
    final completedAt = (await reload(day.id)).completedAt;

    clock.advance(const Duration(minutes: 1));
    await repo.markOffered(day.id);
    await repo.markOpened(day.id);
    final row = await reload(day.id);
    expect(row.status, DayStatus.completed);
    expect(row.completedAt, completedAt);
    expect(row.openedAt, isNotNull, reason: 'lege openedAt wordt wel gevuld');

    final openedAt = row.openedAt;
    clock.advance(const Duration(minutes: 1));
    await repo.markOpened(day.id);
    expect((await reload(day.id)).openedAt, openedAt);
  });

  test('opnieuw markeren wijzigt niets en raakt dirty niet', () async {
    final day = days.first;
    await repo.markOffered(day.id);
    await db.update(db.programmeDays).write(
          const ProgrammeDaysCompanion(dirty: Value(false)),
        );
    await repo.markOffered(day.id);
    expect((await reload(day.id)).dirty, isFalse);
  });

  test('overgeslagen dagen blijven overgeslagen', () async {
    final day = days.first;
    await repo.skip(day.id);
    await repo.markOpened(day.id);
    final row = await reload(day.id);
    expect(row.status, DayStatus.skipped);
    expect(row.openedAt, isNull);
  });

  test('afgeronde dag kan niet worden overgeslagen of vervangen', () async {
    final day = days.first;
    await repo.markCompleted(day.id);
    await expectLater(
        repo.skip(day.id), throwsA(isA<ProgrammeStateError>()));
    await expectLater(repo.replace(day.id, contentId: 'x'),
        throwsA(isA<ProgrammeStateError>()));
  });

  test('vervangen en grootte instellen', () async {
    final day = days[1];
    await repo.setSize(day.id, DaySize.smaller);
    await repo.replace(day.id, contentId: 'alt', snapshot: {'t': 1});
    final row = await reload(day.id);
    expect(row.size, DaySize.smaller);
    expect(row.status, DayStatus.replaced);
    expect(row.contentId, 'alt');
    expect(row.snapshot, {'t': 1});
  });

  group('zelfrapportage', () {
    test('blocker alleen bij partly of no', () async {
      final day = days.first;
      await expectLater(
        repo.recordCheckin(day.id, fit: DayFit.well, blocker: DayBlocker.time),
        throwsA(isA<InvalidValueError>()),
      );
      await expectLater(
        repo.recordCheckin(day.id, fit: DayFit.skip, blocker: DayBlocker.time),
        throwsA(isA<InvalidValueError>()),
      );
      expect((await reload(day.id)).fit, isNull);

      await repo.recordCheckin(day.id,
          fit: DayFit.partly, blocker: DayBlocker.moment);
      var row = await reload(day.id);
      expect(row.fit, DayFit.partly);
      expect(row.blocker, DayBlocker.moment);

      await repo.recordCheckin(day.id, fit: DayFit.well);
      row = await reload(day.id);
      expect(row.fit, DayFit.well);
      expect(row.blocker, isNull);
    });

    test('restedScore is 1 tot 5', () async {
      final day = days.first;
      for (final bad in [0, 6, -1]) {
        await expectLater(
          repo.recordMorningCheck(day.id,
              protected: DayProtected.yes, restedScore: bad),
          throwsA(isA<InvalidValueError>()),
        );
      }
      await repo.recordMorningCheck(day.id,
          protected: DayProtected.partly, restedScore: 5);
      var row = await reload(day.id);
      expect(row.protected, DayProtected.partly);
      expect(row.restedScore, 5);
      await repo.recordMorningCheck(day.id, protected: DayProtected.skip);
      row = await reload(day.id);
      expect(row.restedScore, isNull);
    });
  });

  test('maar een lopende deelname tegelijk', () async {
    await expectLater(
      repo.enroll(
        contentVersion: 'v1',
        selection: const {},
        startedOn: DateTime(2026, 3, 2),
      ),
      throwsA(isA<AlreadyEnrolledError>()),
    );
    await repo.pause(enrollmentId);
    await expectLater(
      repo.enroll(
        contentVersion: 'v1',
        selection: const {},
        startedOn: DateTime(2026, 3, 2),
      ),
      throwsA(isA<AlreadyEnrolledError>()),
    );
    await repo.stop(enrollmentId);
    expect(await repo.watchActiveEnrollment().first, isNull);
    final again = await repo.enroll(
      contentVersion: 'v2',
      selection: const {},
      startedOn: DateTime(2026, 4, 1),
    );
    expect(again.status, EnrollmentStatus.active);
  });

  test('de database dwingt een lopende deelname ook zelf af', () async {
    final profile = await db.select(db.profiles).getSingle();
    await expectLater(
      db.into(db.programmeEnrollments).insert(
            ProgrammeEnrollmentsCompanion.insert(
              profileId: profile.id,
              contentVersion: 'v9',
              startedOn: '2026-03-02',
              updatedAt: clock.current.toUtc(),
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test('pauzeren, hervatten en afronden', () async {
    await repo.pause(enrollmentId);
    expect((await repo.watchActiveEnrollment().first)!.status,
        EnrollmentStatus.paused);
    await expectLater(
        repo.pause(enrollmentId), throwsA(isA<ProgrammeStateError>()));
    await repo.resume(enrollmentId);
    await repo.complete(enrollmentId, ProgrammeDirection.adjust);
    final row = await db.select(db.programmeEnrollments).getSingle();
    expect(row.status, EnrollmentStatus.completed);
    expect(row.direction, ProgrammeDirection.adjust);
    expect(row.completedAt, isNotNull);
    await expectLater(
        repo.resume(enrollmentId), throwsA(isA<ProgrammeStateError>()));
  });

  test('(enrollment_id, day_number) is uniek', () async {
    await expectLater(
      repo.createDays(enrollmentId, [
        DaySeed(
          dayNumber: 3,
          contentId: 'dubbel',
          scheduledFor: DateTime(2026, 3, 9),
        ),
      ]),
      throwsA(isA<Exception>()),
    );
    expect(await repo.watchDays(enrollmentId).first, hasLength(14));
  });

  test('dagnummer buiten 1 tot 14 wordt geweigerd', () async {
    await expectLater(
      repo.createDays(enrollmentId, [
        DaySeed(dayNumber: 15, contentId: 'x', scheduledFor: DateTime(2026, 3, 9)),
      ]),
      throwsA(isA<InvalidValueError>()),
    );
  });

  test('dagen verdwijnen mee met hun deelname (cascade)', () async {
    await db.delete(db.programmeEnrollments).go();
    expect(await db.select(db.programmeDays).get(), isEmpty);
  });
}
