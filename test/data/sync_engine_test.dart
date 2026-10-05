import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/converters.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/repositories/block_profile_repository.dart';
import 'package:rest4more/data/repositories/focus_session_repository.dart';
import 'package:rest4more/data/repositories/routine_repository.dart';
import 'package:rest4more/data/sync/sync_engine.dart';
import 'package:rest4more/data/sync/sync_remote.dart';

import 'test_support.dart';

/// Nep-server: bewaart rijen per tabel en stempelt `synced_at` oplopend, net
/// als de trigger op de echte server. Meerdere [FakeRemote]s kunnen er een
/// delen om twee toestellen na te bootsen.
class FakeServer {
  final tables = <String, Map<String, Map<String, Object?>>>{};
  var _tick = 0;

  /// Stempelt de rij en bewaart hem. Een oudere `updated_at` wordt genegeerd.
  void store(String table, Map<String, Object?> row) {
    final rows = tables.putIfAbsent(table, () => {});
    final existing = rows[row['id']];
    if (existing != null &&
        DateTime.parse(row['updated_at'] as String)
            .isBefore(DateTime.parse(existing['updated_at'] as String))) {
      return;
    }
    _tick++;
    rows[row['id'] as String] = {
      ...row,
      'user_id': 'user-1',
      'synced_at': DateTime.utc(2026, 1, 1).add(Duration(seconds: _tick))
          .toIso8601String(),
    };
  }

  List<Map<String, Object?>> fetch(
    String table, {
    SyncPosition? after,
    required int limit,
  }) {
    final all = (tables[table]?.values.toList() ?? [])
      ..sort((a, b) {
        final c = DateTime.parse(a['synced_at'] as String)
            .compareTo(DateTime.parse(b['synced_at'] as String));
        return c != 0 ? c : (a['id'] as String).compareTo(b['id'] as String);
      });
    final filtered = all.where((row) {
      if (after == null) return true;
      final t = DateTime.parse(row['synced_at'] as String);
      final a = DateTime.parse(after.syncedAt);
      return t.isAfter(a) ||
          (t.isAtSameMomentAs(a) && (row['id'] as String).compareTo(after.id) > 0);
    });
    return filtered.take(limit).map((r) => Map<String, Object?>.from(r)).toList();
  }
}

class FakeRemote implements SyncRemote {
  FakeRemote({FakeServer? server}) : server = server ?? FakeServer();

  final FakeServer server;
  final fetches = <(String, SyncPosition?)>[];
  Object? fetchFailsFor;

  @override
  Future<List<Map<String, Object?>>> fetchChanges(
    String table, {
    SyncPosition? after,
    int limit = 200,
  }) async {
    if (failWith != null) throw failWith!;
    if (fetchFailsFor == table) throw Exception('fetch $table mislukt');
    fetches.add((table, after));
    return server.fetch(table, after: after, limit: limit);
  }

  final calls = <(String, List<Map<String, Object?>>)>[];
  Object? failWith;
  void Function()? onUpsert;
  var signedIn = 0;
  var activity = 0;
  Object? activityFails;

  String? userId = 'user-1';

  @override
  String? get currentUserId => userId;

  @override
  Future<void> recordActivity() async {
    if (activityFails != null) throw activityFails!;
    activity++;
  }

  @override
  Future<void> ensureSignedIn() async => signedIn++;

  @override
  Future<void> upsert(String table, List<Map<String, Object?>> rows) async {
    if (failWith != null) throw failWith!;
    onUpsert?.call();
    calls.add((table, rows));
    for (final row in rows) {
      server.store(table, row);
    }
  }

  Map<String, Object?> exportData = {'profiles': <Object?>[]};
  var deleted = 0;

  @override
  Future<Map<String, Object?>> exportMyData() async {
    if (failWith != null) throw failWith!;
    return exportData;
  }

  @override
  Future<void> deleteMyData() async {
    if (failWith != null) throw failWith!;
    deleted++;
  }

  List<String> get tables => calls.map((c) => c.$1).toList();
  List<Map<String, Object?>> rowsOf(String table) =>
      [for (final c in calls) if (c.$1 == table) ...c.$2];
}

void main() {
  late AppDatabase db;
  late TestClock clock;
  late FakeRemote remote;
  late SyncEngine engine;

  setUp(() {
    db = memoryDb();
    clock = TestClock();
    remote = FakeRemote();
    engine = SyncEngine(db, remote);
  });
  tearDown(() => db.close());

  Future<void> consent() =>
      grantConsent(db, at: clock.current, now: clock.call);

  Future<int> dirtyCount(String table) async {
    final rows = await db
        .customSelect('SELECT COUNT(*) AS c FROM $table WHERE dirty = 1')
        .get();
    return rows.single.read<int>('c');
  }

  test('zonder toestemming wordt niets verstuurd', () async {
    await RoutineRepository(db, now: clock.call)
        .create(mode: 'focus', name: 'Avond');
    final result = await engine.pushDirty();
    expect(result.skippedNoConsent, isTrue);
    expect(result.ok, isFalse);
    expect(remote.calls, isEmpty);
    expect(remote.signedIn, 0);
    expect(await dirtyCount('routines'), 1);
  });

  test('met toestemming gaat alles in volgorde: ouders eerst', () async {
    await consent();
    final block = await BlockProfileRepository(db, now: clock.call)
        .create(name: 'Studie');
    await RoutineRepository(db, now: clock.call)
        .create(mode: 'focus', name: 'Avond', blockProfileId: block.id);
    await FocusSessionRepository(db, now: clock.call).start(
      mode: 'focus',
      source: SessionSource.manual,
      platform: SessionPlatform.android,
    );

    final result = await engine.pushDirty();
    expect(result.ok, isTrue);
    expect(result.pushed, 5);
    expect(remote.signedIn, 1);
    expect(remote.tables, [
      'profiles',
      'consent_records',
      'block_profiles',
      'routines',
      'focus_sessions',
    ]);
    for (final t in [
      'profiles',
      'consent_records',
      'block_profiles',
      'routines',
      'focus_sessions',
    ]) {
      expect(await dirtyCount(t), 0, reason: t);
    }
  });

  test('payload: geen dirty of user_id, echte bools en jsonb, UTC-tijden',
      () async {
    await consent();
    final routines = RoutineRepository(db, now: clock.call);
    final routine = await routines.create(mode: 'focus', name: 'Avond');
    await routines.setSteps(routine.id, const [
      RoutineStepData(title: 'Lezen', durationMin: 5),
    ]);
    await FocusSessionRepository(db, now: clock.call).start(
      mode: 'focus',
      source: SessionSource.nfc,
      platform: SessionPlatform.ios,
    );

    await engine.pushDirty();

    final profile = remote.rowsOf('profiles').single;
    expect(profile.containsKey('dirty'), isFalse);
    expect(profile.containsKey('user_id'), isFalse);
    expect(profile['owns_card'], isFalse);
    expect(profile['cloud_sync_consent_at'], endsWith('Z'));

    final row = remote.rowsOf('routines').single;
    expect(row['enabled'], isTrue);
    expect(row['auto_start'], isFalse);
    expect(row['steps'], [
      {'title': 'Lezen', 'duration_min': 5},
    ]);
    expect(row['deleted_at'], isNull);
    expect(row['end_rule'], 'manual');

    final session = remote.rowsOf('focus_sessions').single;
    expect(session['source'], 'nfc');
    expect(session['events'], isEmpty);
    expect(session['local_date'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    expect((session['started_at'] as String).endsWith('Z'), isTrue);
  });

  test('onbekende enumwaarden gaan letterlijk mee', () async {
    await consent();
    final repo = RoutineRepository(db, now: clock.call);
    await repo.create(mode: 'focus', name: 'a');
    await db.customStatement("UPDATE routines SET end_rule = 'future_value'");
    await engine.pushDirty();
    expect(remote.rowsOf('routines').single['end_rule'], 'future_value');
  });

  test('zacht verwijderde rijen gaan mee als tombstone', () async {
    await consent();
    final repo = RoutineRepository(db, now: clock.call);
    final routine = await repo.create(mode: 'focus', name: 'a');
    await engine.pushDirty();
    clock.advance();
    await repo.softDelete(routine.id);
    remote.calls.clear();
    await engine.pushDirty();
    expect(remote.rowsOf('routines').single['deleted_at'], isNotNull);
  });

  test('een tweede push stuurt alleen wat veranderd is', () async {
    await consent();
    final repo = RoutineRepository(db, now: clock.call);
    final routine = await repo.create(mode: 'focus', name: 'a');
    await engine.pushDirty();
    remote.calls.clear();
    expect((await engine.pushDirty()).pushed, 0);
    expect(remote.calls, isEmpty);

    clock.advance();
    await repo.update(routine.id, name: 'b');
    await engine.pushDirty();
    expect(remote.rowsOf('routines').single['name'], 'b');
  });

  test('bij een fout blijven rijen dirty en is de fout zichtbaar', () async {
    await consent();
    await RoutineRepository(db, now: clock.call)
        .create(mode: 'focus', name: 'a');
    remote.failWith = Exception('offline');
    final result = await engine.pushDirty();
    expect(result.ok, isFalse);
    expect(result.error, isNotNull);
    expect(result.failedTable, 'profiles');
    expect(await dirtyCount('routines'), 1);
    expect(await dirtyCount('profiles'), 1);

    remote.failWith = null;
    expect((await engine.pushDirty()).ok, isTrue);
    expect(await dirtyCount('routines'), 0);
  });

  test('zonder remote blijft alles dirty', () async {
    await consent();
    await RoutineRepository(db, now: clock.call)
        .create(mode: 'focus', name: 'a');
    final result =
        await SyncEngine(db, const UnavailableSyncRemote()).pushDirty();
    expect(result.error, isA<SyncUnavailableError>());
    expect(await dirtyCount('routines'), 1);
  });

  test('een bewerking tijdens het versturen blijft dirty', () async {
    await consent();
    final repo = RoutineRepository(db, now: clock.call);
    final routine = await repo.create(mode: 'focus', name: 'a');
    final racing = _RacingRemote(() async {
      clock.advance();
      await repo.update(routine.id, name: 'nieuw');
    });
    await SyncEngine(db, racing).pushDirty();
    expect(await dirtyCount('routines'), 1, reason: 'bewerking niet kwijt');

    await engine.pushDirty();
    expect(remote.rowsOf('routines').single['name'], 'nieuw');
  });

  test('grote hoeveelheden gaan in batches', () async {
    await consent();
    final repo = RoutineRepository(db, now: clock.call);
    for (var i = 0; i < 5; i++) {
      clock.advance();
      await repo.create(mode: 'focus', name: 'r$i');
    }
    final result = await SyncEngine(db, remote, batchSize: 2).pushDirty();
    expect(result.pushed, 7);
    expect(remote.rowsOf('routines'), hasLength(5));
    expect(await dirtyCount('routines'), 0);
  });

  test('entitlements en lokale tabellen worden nooit verstuurd', () async {
    await consent();
    await db.customStatement('''INSERT INTO entitlements
      (id, updated_at, dirty, feature, source, status, starts_at)
      VALUES ('e1', '2026-03-02T10:00:00.000Z', 1, 'extra', 'grant', 'active',
      '2026-01-01T00:00:00.000Z')''');
    await engine.pushDirty();
    expect(remote.tables, isNot(contains('entitlements')));
    expect(remote.tables, isNot(contains('ios_selections')));
    expect(remote.tables, isNot(contains('local_notifications')));
  });
}

/// Bewerkt een rij op het moment dat de routines worden verstuurd.
class _RacingRemote extends FakeRemote {
  _RacingRemote(this._edit);

  final Future<void> Function() _edit;
  var _done = false;

  @override
  Future<void> upsert(String table, List<Map<String, Object?>> rows) async {
    await super.upsert(table, rows);
    if (table == 'routines' && !_done) {
      _done = true;
      await _edit();
    }
  }
}
