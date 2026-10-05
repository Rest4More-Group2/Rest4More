import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/data/repositories/programme_repository.dart';
import 'package:rest4more/data/repositories/routine_repository.dart';
import 'package:rest4more/data/sync/debug_seed.dart';
import 'package:rest4more/data/sync/pull_engine.dart';
import 'package:rest4more/data/sync/sync_engine.dart';

import 'sync_engine_test.dart' show FakeRemote, FakeServer;
import 'test_support.dart';

void main() {
  late FakeServer server;
  late AppDatabase deviceA;
  late AppDatabase deviceB;
  late FakeRemote remoteA;
  late FakeRemote remoteB;

  setUp(() async {
    server = FakeServer();
    deviceA = memoryDb();
    deviceB = memoryDb();
    remoteA = FakeRemote(server: server);
    remoteB = FakeRemote(server: server);
    // Toestel A heeft data en heeft die naar de server gepusht.
    expect(await seedDebugData(deviceA), isTrue);
    await grantConsent(deviceA);
    expect((await SyncEngine(deviceA, remoteA).pushDirty()).ok, isTrue);
  });
  tearDown(() async {
    await deviceA.close();
    await deviceB.close();
  });

  Future<List<Map<String, Object?>>> rows(AppDatabase db, String table,
          [String order = 'id']) async =>
      (await db.customSelect('SELECT * FROM $table ORDER BY $order').get())
          .map((r) => r.data)
          .toList();

  Future<void> expectSame(String table) async {
    final a = await rows(deviceA, table);
    final b = await rows(deviceB, table);
    expect(b.length, a.length, reason: table);
    for (var i = 0; i < a.length; i++) {
      final left = {...a[i]}..remove('dirty');
      final right = {...b[i]}..remove('dirty');
      expect(right, left, reason: '$table rij $i');
    }
  }

  test('een leeg toestel krijgt alle gegevens van de server terug', () async {
    // B heeft alleen het automatisch aangemaakte lege profiel.
    final localProfile = await ProfileRepository(deviceB).get();

    final result = await PullEngine(deviceB, remoteB).pull();
    expect(result.ok, isTrue);
    expect(result.skipped, 0);
    expect(result.conflicts, isEmpty);

    for (final table in [
      'profiles',
      'consent_records',
      'block_profiles',
      'routines',
      'accessories',
      'focus_sessions',
      'programme_enrollments',
      'programme_days',
    ]) {
      await expectSame(table);
    }
    final profiles = await rows(deviceB, 'profiles');
    expect(profiles, hasLength(1));
    expect(profiles.single['id'], isNot(localProfile.id),
        reason: 'het lege profiel is vervangen');
    expect(await rows(deviceB, 'programme_days'), hasLength(14));
  });

  test('opgehaalde rijen zijn niet dirty en veroorzaken geen push', () async {
    await PullEngine(deviceB, remoteB).pull();
    for (final table in ['profiles', 'routines', 'programme_days']) {
      final dirty = await deviceB
          .customSelect('SELECT COUNT(*) AS c FROM $table WHERE dirty = 1')
          .getSingle();
      expect(dirty.read<int>('c'), 0, reason: table);
    }
    remoteB.calls.clear();
    final push = await SyncEngine(deviceB, remoteB).pushDirty();
    expect(push.ok, isTrue);
    expect(remoteB.calls, isEmpty);
  });

  test('types komen goed over: bools, json, tijden en onbekende enumwaarden',
      () async {
    server.store('routines', {
      ...server.tables['routines']!.values.first,
      'end_rule': 'future_value',
      'auto_start': true,
      'steps': [
        {'title': 'Lezen', 'duration_min': 5},
      ],
      'updated_at': '2030-01-01T00:00:00+00:00',
    });
    await PullEngine(deviceB, remoteB).pull();

    final routine = (await rows(deviceB, 'routines')).single;
    expect(routine['end_rule'], 'future_value');
    expect(routine['auto_start'], 1);
    expect(routine['steps'], '[{"title":"Lezen","duration_min":5}]');
    expect(routine['updated_at'], '2030-01-01T00:00:00.000Z');

    final typed = await RoutineRepository(deviceB).watchAll().first;
    expect(typed.single.endRule, EndRuleUnknown.value);
  });

  group('conflicten', () {
    test('nieuwere serverversie wint, ook van een lokale wijziging', () async {
      await PullEngine(deviceB, remoteB).pull();
      final routineId = (await rows(deviceB, 'routines')).single['id'] as String;

      await RoutineRepository(deviceB, now: () => DateTime.utc(2030, 6, 1))
          .update(routineId, name: 'lokaal');
      server.store('routines', {
        ...server.tables['routines']![routineId]!,
        'name': 'server',
        'updated_at': '2031-01-01T00:00:00Z',
      });
      await PullEngine(deviceB, remoteB).pull();

      final row = (await rows(deviceB, 'routines')).single;
      expect(row['name'], 'server');
      expect(row['dirty'], 0);
    });

    test('nieuwere lokale wijziging blijft staan en gaat daarna omhoog',
        () async {
      await PullEngine(deviceB, remoteB).pull();
      final routineId = (await rows(deviceB, 'routines')).single['id'] as String;

      await RoutineRepository(deviceB, now: () => DateTime.utc(2032, 1, 1))
          .update(routineId, name: 'lokaal-nieuw');
      server.store('routines', {
        ...server.tables['routines']![routineId]!,
        'name': 'server-oud',
        'updated_at': '2031-01-01T00:00:00Z',
      });
      await PullEngine(deviceB, remoteB).pull();

      final row = (await rows(deviceB, 'routines')).single;
      expect(row['name'], 'lokaal-nieuw');
      expect(row['dirty'], 1);
    });

    test('verwijderde rij (tombstone) van de server verbergt de rij lokaal',
        () async {
      await PullEngine(deviceB, remoteB).pull();
      final routineId = (await rows(deviceB, 'routines')).single['id'] as String;
      server.store('routines', {
        ...server.tables['routines']![routineId]!,
        'deleted_at': '2031-01-01T00:00:00Z',
        'updated_at': '2031-01-01T00:00:00Z',
      });
      await PullEngine(deviceB, remoteB).pull();
      expect(await RoutineRepository(deviceB).watchAll().first, isEmpty);
      expect((await rows(deviceB, 'routines')).single['deleted_at'], isNotNull);
    });

    test('een lokaal profiel met gegevens wordt niet overschreven', () async {
      await ProfileRepository(deviceB)
          .upsert(const ProfileDraft(displayName: 'Lokaal'));
      final result = await PullEngine(deviceB, remoteB).pull();
      expect(result.conflicts, hasLength(1));
      final profiles = await rows(deviceB, 'profiles');
      expect(profiles, hasLength(1));
      expect(profiles.single['display_name'], 'Lokaal');
    });

    test('een tweede open sessie past niet: overgeslagen, de rest gaat door',
        () async {
      // Zet op A een open sessie op de server.
      await deviceA.customStatement(
          'UPDATE focus_sessions SET ended_at = NULL, state = \'active\'');
      await deviceA.customStatement('UPDATE focus_sessions SET dirty = 1');
      await SyncEngine(deviceA, remoteA).pushDirty();
      // B heeft al een eigen open sessie.
      await deviceB.customStatement('''INSERT INTO focus_sessions
        (id, mode, source, platform, state, started_at, local_date, events,
         updated_at, dirty) VALUES ('b-open', 'focus', 'manual', 'ios',
        'selecting', '2026-03-02T10:00:00.000Z', '2026-03-02', '[]',
        '2026-03-02T10:00:00.000Z', 1)''');

      final result = await PullEngine(deviceB, remoteB).pull();
      expect(result.ok, isTrue);
      expect(result.skipped, 1);
      expect(await rows(deviceB, 'routines'), hasLength(1),
          reason: 'andere tabellen zijn wel opgehaald');
    });
  });

  group('voortgang', () {
    test('de cursor wordt bewaard en een tweede pull haalt niets nieuws',
        () async {
      await PullEngine(deviceB, remoteB).pull();
      final cursors = await deviceB.select(deviceB.syncCursors).get();
      expect(cursors.map((c) => c.targetTable),
          containsAll(['profiles', 'routines', 'programme_days']));

      final again = await PullEngine(deviceB, remoteB, overlap: Duration.zero)
          .pull();
      expect(again.applied, 0);
    });

    test('een nieuwe wijziging op de server wordt opgepikt', () async {
      await PullEngine(deviceB, remoteB).pull();
      await RoutineRepository(deviceA).create(mode: 'focus', name: 'Nieuw');
      await SyncEngine(deviceA, remoteA).pushDirty();

      final result = await PullEngine(deviceB, remoteB).pull();
      expect(result.applied, greaterThanOrEqualTo(1));
      expect(await rows(deviceB, 'routines'), hasLength(2));
    });

    test('opnieuw ophalen met overlap past niets dubbel toe', () async {
      final first = await PullEngine(deviceB, remoteB).pull();
      final second = await PullEngine(deviceB, remoteB).pull();
      expect(first.applied, greaterThan(0));
      expect(second.applied, 0);
      expect(await rows(deviceB, 'programme_days'), hasLength(14));
    });

    test('kleine pagina\'s halen toch alles op', () async {
      final result = await PullEngine(deviceB, remoteB, pageSize: 3).pull();
      expect(result.ok, isTrue);
      expect(await rows(deviceB, 'programme_days'), hasLength(14));
      expect(remoteB.fetches.where((f) => f.$1 == 'programme_days').length,
          greaterThan(3));
    });

    test('een onderbroken pull gaat verder en verliest niets', () async {
      remoteB.fetchFailsFor = 'routines';
      final broken = await PullEngine(deviceB, remoteB).pull();
      expect(broken.ok, isFalse);
      expect(broken.failedTable, 'routines');
      expect(await rows(deviceB, 'profiles'), hasLength(1));
      expect(await rows(deviceB, 'routines'), isEmpty);

      remoteB.fetchFailsFor = null;
      final resumed = await PullEngine(deviceB, remoteB).pull();
      expect(resumed.ok, isTrue);
      expect(await rows(deviceB, 'routines'), hasLength(1));
      expect(await rows(deviceB, 'programme_days'), hasLength(14));
    });
  });

  test('zonder sessie wordt er niets opgehaald', () async {
    remoteB.userId = null;
    final result = await PullEngine(deviceB, remoteB).pull();
    expect(result.skippedNoSession, isTrue);
    expect(result.ok, isFalse);
    expect(remoteB.fetches, isEmpty);
  });

  group('rechten', () {
    test('worden vervangen door de lijst van de server', () async {
      server.store('entitlements', {
        'id': 'e1',
        'feature': 'extra',
        'source': 'grant',
        'status': 'active',
        'starts_at': '2026-01-01T00:00:00+00:00',
        'ends_at': null,
        'updated_at': '2026-01-01T00:00:00+00:00',
        'deleted_at': null,
      });
      server.store('entitlements', {
        'id': 'e2',
        'feature': 'oud',
        'source': 'free',
        'status': 'expired',
        'starts_at': '2025-01-01T00:00:00+00:00',
        'ends_at': '2025-06-01T00:00:00+00:00',
        'updated_at': '2025-06-01T00:00:00+00:00',
        'deleted_at': '2025-06-01T00:00:00+00:00',
      });
      await PullEngine(deviceB, remoteB).pull();
      final all = await deviceB.select(deviceB.entitlements).get();
      expect(all.map((e) => e.id), ['e1']);
      expect(all.single.source, EntitlementSource.grant);
      expect(all.single.dirty, isFalse);

      // Server trekt het recht in: lokaal verdwijnt het.
      server.tables['entitlements']!.remove('e1');
      await PullEngine(deviceB, remoteB).pull();
      expect(await deviceB.select(deviceB.entitlements).get(), isEmpty);
    });
  });

  test('een programma van een ander toestel is meteen bruikbaar', () async {
    await PullEngine(deviceB, remoteB).pull();
    final programme = ProgrammeRepository(deviceB);
    final enrollment = await programme.watchActiveEnrollment().first;
    expect(enrollment, isNotNull);
    final days = await programme.watchDays(enrollment!.id).first;
    expect(days, hasLength(14));
    expect(days.first.status, DayStatus.completed);
  });
}

/// Hulp om een onbekende enumwaarde te controleren zonder magische tekst.
class EndRuleUnknown {
  static const value = RoutineEndRule.unknown;
}
