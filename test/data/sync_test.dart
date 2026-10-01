import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/repositories/accessory_repository.dart';
import 'package:rest4more/data/repositories/block_profile_repository.dart';
import 'package:rest4more/data/repositories/focus_session_repository.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/data/repositories/programme_repository.dart';
import 'package:rest4more/data/repositories/routine_repository.dart';

import 'test_support.dart';

void main() {
  late AppDatabase db;
  late TestClock clock;

  setUp(() {
    db = memoryDb();
    clock = TestClock();
  });
  tearDown(() => db.close());

  /// Voert [write] uit na het leegmaken van `dirty`, een milliseconde later,
  /// en controleert dat `dirty` en `updatedAt` zijn bijgewerkt.
  Future<void> expectWriteSyncs<T>({
    required Future<T> Function() read,
    required DateTime Function(T) updatedAt,
    required bool Function(T) dirty,
    required Future<void> Function() clearDirty,
    required Future<void> Function() write,
  }) async {
    final before = updatedAt(await read());
    await clearDirty();
    expect(dirty(await read()), isFalse);
    clock.advance(); // een milliseconde: dezelfde seconde
    await write();
    final after = await read();
    expect(dirty(after), isTrue);
    expect(updatedAt(after).isAfter(before), isTrue);
  }

  test('profiel: schrijven zet dirty en verplaatst updatedAt', () async {
    final repo = ProfileRepository(db, now: clock.call);
    await expectWriteSyncs<Profile>(
      read: repo.get,
      updatedAt: (r) => r.updatedAt,
      dirty: (r) => r.dirty,
      clearDirty: () => (db.update(db.profiles))
          .write(const ProfilesCompanion(dirty: Value(false))),
      write: () => repo.upsert(const ProfileDraft(displayName: 'Sam')),
    );
  });

  test('routine: schrijven zet dirty en verplaatst updatedAt', () async {
    final repo = RoutineRepository(db, now: clock.call);
    final routine = await repo.create(mode: 'focus', name: 'Avond');
    await expectWriteSyncs<Routine>(
      read: () => db.select(db.routines).getSingle(),
      updatedAt: (r) => r.updatedAt,
      dirty: (r) => r.dirty,
      clearDirty: () => db
          .update(db.routines)
          .write(const RoutinesCompanion(dirty: Value(false))),
      write: () => repo.update(routine.id, name: 'Nacht'),
    );
  });

  test('blokkeerprofiel: schrijven zet dirty en verplaatst updatedAt', () async {
    final repo = BlockProfileRepository(db, now: clock.call);
    final profile = await repo.create(name: 'Studie');
    await expectWriteSyncs<BlockProfile>(
      read: () => db.select(db.blockProfiles).getSingle(),
      updatedAt: (r) => r.updatedAt,
      dirty: (r) => r.dirty,
      clearDirty: () => db
          .update(db.blockProfiles)
          .write(const BlockProfilesCompanion(dirty: Value(false))),
      write: () => repo.update(profile.id, name: 'Werk'),
    );
  });

  test('accessoire: schrijven zet dirty en verplaatst updatedAt', () async {
    final repo = AccessoryRepository(db, now: clock.call);
    final card = await repo.pairCard(tokenHash: 'h', label: 'Kaart');
    await expectWriteSyncs<Accessory>(
      read: () => db.select(db.accessories).getSingle(),
      updatedAt: (r) => r.updatedAt,
      dirty: (r) => r.dirty,
      clearDirty: () => db
          .update(db.accessories)
          .write(const AccessoriesCompanion(dirty: Value(false))),
      write: () => repo.markLost(card.id),
    );
  });

  test('focussessie: schrijven zet dirty en verplaatst updatedAt', () async {
    final repo = FocusSessionRepository(db, now: clock.call);
    final session = await startSession(repo);
    await expectWriteSyncs<FocusSession>(
      read: () => db.select(db.focusSessions).getSingle(),
      updatedAt: (r) => r.updatedAt,
      dirty: (r) => r.dirty,
      clearDirty: () => db
          .update(db.focusSessions)
          .write(const FocusSessionsCompanion(dirty: Value(false))),
      write: () => repo.transition(session.id, SessionState.awaitingScan),
    );
  });

  test('programma: schrijven zet dirty en verplaatst updatedAt', () async {
    final repo = ProgrammeRepository(db, now: clock.call);
    final enrollmentId = await enrollWithDays(repo);
    await expectWriteSyncs<ProgrammeEnrollment>(
      read: () => db.select(db.programmeEnrollments).getSingle(),
      updatedAt: (r) => r.updatedAt,
      dirty: (r) => r.dirty,
      clearDirty: () => db
          .update(db.programmeEnrollments)
          .write(const ProgrammeEnrollmentsCompanion(dirty: Value(false))),
      write: () => repo.pause(enrollmentId),
    );
    final day = (await db.select(db.programmeDays).get()).first;
    await expectWriteSyncs<ProgrammeDay>(
      read: () => (db.select(db.programmeDays)
            ..where((t) => t.id.equals(day.id)))
          .getSingle(),
      updatedAt: (r) => r.updatedAt,
      dirty: (r) => r.dirty,
      clearDirty: () => db
          .update(db.programmeDays)
          .write(const ProgrammeDaysCompanion(dirty: Value(false))),
      write: () => repo.setSize(day.id, DaySize.smaller),
    );
  });

  test('zacht verwijderen verbergt de rij, maar bewaart hem', () async {
    final routines = RoutineRepository(db, now: clock.call);
    final blocks = BlockProfileRepository(db, now: clock.call);
    final routine = await routines.create(mode: 'focus', name: 'Avond');
    final block = await blocks.create(name: 'Studie');
    expect(await routines.watchAll().first, hasLength(1));
    expect(await blocks.watchAll().first, hasLength(1));

    clock.advance();
    await routines.softDelete(routine.id);
    await blocks.softDelete(block.id);

    expect(await routines.watchAll().first, isEmpty);
    expect(await blocks.watchAll().first, isEmpty);
    final row = await db.select(db.routines).getSingle();
    expect(row.deletedAt, isNotNull);
    expect(row.dirty, isTrue);
    expect((await db.select(db.blockProfiles).getSingle()).deletedAt, isNotNull);
  });

  test('lokale tabellen hebben geen synckolommen', () {
    for (final TableInfo table in [db.iosSelections, db.localNotifications]) {
      final names = table.$columns.map((c) => c.$name).toSet();
      expect(names, isNot(contains('dirty')));
      expect(names, isNot(contains('deleted_at')));
      expect(names, isNot(contains('updated_at')));
    }
  });

  test('gesynchroniseerde tabellen hebben alle synckolommen', () {
    final List<TableInfo> tables = [
      db.profiles,
      db.routines,
      db.blockProfiles,
      db.accessories,
      db.focusSessions,
      db.programmeEnrollments,
      db.programmeDays,
      db.entitlements,
    ];
    for (final table in tables) {
      final names = table.$columns.map((c) => c.$name).toSet();
      expect(names, containsAll(['id', 'updated_at', 'deleted_at', 'dirty']));
    }
  });
}
