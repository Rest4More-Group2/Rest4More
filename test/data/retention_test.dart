import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/repositories/focus_session_repository.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/data/repositories/programme_repository.dart';
import 'package:rest4more/data/repositories/routine_repository.dart';
import 'package:rest4more/data/sync/retention_service.dart';

import 'test_support.dart';

void main() {
  late AppDatabase db;
  late TestClock clock;
  late RetentionService retention;
  late RoutineRepository routines;

  setUp(() {
    db = memoryDb();
    clock = TestClock(DateTime(2026, 3, 2, 10));
    routines = RoutineRepository(db, now: clock.call);
    retention = RetentionService(db, now: clock.call);
  });
  tearDown(() => db.close());

  Future<String> deletedRoutine(DateTime deletedAt, {bool dirty = false}) async {
    final routine = await routines.create(mode: 'focus', name: 'r');
    final stamp = deletedAt.toUtc().toIso8601String();
    await db.customStatement(
      "UPDATE routines SET deleted_at = '$stamp', dirty = ${dirty ? 1 : 0} "
      "WHERE id = '${routine.id}'",
    );
    return routine.id;
  }

  Future<int> routineCount() async =>
      (await db.select(db.routines).get()).length;

  test('verwijderde rij ouder dan 2 jaar wordt gewist', () async {
    await deletedRoutine(DateTime(2024, 3, 1));
    final removed = await retention.purgeOldTombstones();
    expect(removed['routines'], 1);
    expect(await routineCount(), 0);
  });

  test('jonger dan 2 jaar blijft staan, ook vlak voor de grens', () async {
    await deletedRoutine(DateTime(2024, 3, 3));
    await deletedRoutine(DateTime(2025, 12, 1));
    await retention.purgeOldTombstones();
    expect(await routineCount(), 2);
  });

  test('een niet verwijderde rij blijft staan, hoe oud ook', () async {
    await routines.create(mode: 'focus', name: 'oud');
    await db.customStatement("UPDATE routines SET updated_at = '2020-01-01T00:00:00.000Z'");
    await retention.purgeOldTombstones();
    expect(await routineCount(), 1);
  });

  test('met toestemming blijft een nog niet gepushte verwijdering staan',
      () async {
    await ProfileRepository(db, now: clock.call)
        .recordCloudSyncConsent(clock.current);
    await deletedRoutine(DateTime(2023, 1, 1), dirty: true);
    await deletedRoutine(DateTime(2023, 1, 1), dirty: false);
    await retention.purgeOldTombstones();
    expect(await routineCount(), 1);
    expect((await db.select(db.routines).getSingle()).dirty, isTrue);
  });

  test('zonder toestemming gaat ook een niet gepushte verwijdering weg',
      () async {
    await deletedRoutine(DateTime(2023, 1, 1), dirty: true);
    await retention.purgeOldTombstones();
    expect(await routineCount(), 0);
  });

  test('de termijn is instelbaar', () async {
    await deletedRoutine(DateTime(2025, 1, 1));
    await RetentionService(db, years: 1, now: clock.call).purgeOldTombstones();
    expect(await routineCount(), 0);
  });

  test('sessiegeschiedenis blijft, alleen de verwijzing naar de routine gaat',
      () async {
    final routineId = await deletedRoutine(DateTime(2023, 1, 1));
    final sessions = FocusSessionRepository(db, now: clock.call);
    final session = await sessions.start(
      mode: 'focus',
      source: SessionSource.manual,
      platform: SessionPlatform.android,
      routineId: routineId,
    );
    await retention.purgeOldTombstones();
    final row = await db.select(db.focusSessions).getSingle();
    expect(row.id, session.id);
    expect(row.routineId, isNull);
  });

  test('een verlopen deelname neemt zijn dagen mee', () async {
    final programme = ProgrammeRepository(db, now: clock.call);
    final id = await enrollWithDays(programme);
    await db.customStatement(
      "UPDATE programme_enrollments SET deleted_at = '2023-01-01T00:00:00.000Z', "
      "dirty = 0 WHERE id = '$id'",
    );
    final removed = await retention.purgeOldTombstones();
    expect(removed['programme_enrollments'], 1);
    expect(await db.select(db.programmeEnrollments).get(), isEmpty);
    expect(await db.select(db.programmeDays).get(), isEmpty);
  });

  test('een profiel waar nog een deelname naar verwijst blijft staan',
      () async {
    final programme = ProgrammeRepository(db, now: clock.call);
    await enrollWithDays(programme);
    await db.customStatement(
      "UPDATE profiles SET deleted_at = '2023-01-01T00:00:00.000Z', dirty = 0",
    );
    await retention.purgeOldTombstones();
    expect(await db.select(db.profiles).get(), hasLength(1));
  });
}
