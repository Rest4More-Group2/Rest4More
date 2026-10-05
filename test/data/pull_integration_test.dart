import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/encrypted_database.dart';
import 'package:rest4more/data/repositories/routine_repository.dart';
import 'package:rest4more/data/sync/cloud_data_service.dart';
import 'package:rest4more/data/sync/local_data_service.dart';
import 'package:rest4more/data/sync/pull_engine.dart';
import 'package:rest4more/data/sync/sync_engine.dart';
import 'package:rest4more/data/sync/sync_scheduler.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';

import 'sync_engine_test.dart' show FakeRemote;
import 'sync_scheduler_test.dart' show MemoryStateStore;
import 'test_support.dart';

const _keyA =
    '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff';
const _keyB =
    'ffeeddccbbaa99887766554433221100ffeeddccbbaa99887766554433221100';

void main() {
  late AppDatabase db;
  late FakeRemote remote;
  late MemoryStateStore state;

  setUp(() async {
    db = memoryDb();
    remote = FakeRemote();
    state = MemoryStateStore();
    await grantConsent(db);
    await RoutineRepository(db).create(mode: 'focus', name: 'Avond');
  });
  tearDown(() => db.close());

  test('de scheduler haalt eerst op en pusht daarna, in die volgorde',
      () async {
    final order = <String>[];
    final engine = SyncEngine(db, remote, state: state);
    final scheduler = SyncScheduler(
      engine,
      state,
      now: () => DateTime(2026, 3, 2, 9),
      beforePush: () async => order.add('erasure'),
      pull: () async {
        order.add('pull');
        final r = await PullEngine(db, remote).pull();
        order.add('pulled:${r.ok}');
      },
    );
    addTearDown(scheduler.dispose);
    await scheduler.maybePush();
    order.add(remote.calls.isEmpty ? 'geen-push' : 'push');
    expect(order, ['erasure', 'pull', 'pulled:true', 'push']);
  });

  test('mislukt het ophalen, dan wordt er niet gepusht en later opnieuw',
      () async {
    var failing = true;
    final scheduler = SyncScheduler(
      SyncEngine(db, remote, state: state),
      state,
      retryInterval: const Duration(milliseconds: 50),
      pull: () async {
        if (failing) throw Exception('offline');
      },
    );
    addTearDown(scheduler.dispose);
    await scheduler.maybePush();
    expect(remote.calls, isEmpty);
    expect(state.date, isNull);

    failing = false;
    await Future.delayed(const Duration(milliseconds: 250));
    expect(remote.rowsOf('routines'), hasLength(1));
    expect(state.date, isNotNull);
  });

  test('een ander account wist de voortgang van de pull', () async {
    await db.customStatement(
        "INSERT INTO sync_cursors (target_table, cursor) VALUES ('routines', 'x')");
    final engine = SyncEngine(db, remote, state: state);
    await engine.pushDirty();
    remote.userId = 'user-2';
    await engine.pushDirty();
    expect(await db.select(db.syncCursors).get(), isEmpty);
  });

  test('wissen van de cloud of het toestel wist ook de voortgang', () async {
    Future<void> seedCursor() => db.customStatement(
        "INSERT OR REPLACE INTO sync_cursors (target_table, cursor) VALUES ('routines', 'x')");
    final profiles = ProfileRepository(db);
    final cloud = CloudDataService(db, remote, state, profiles);

    await seedCursor();
    await cloud.deleteCloudData();
    expect(await db.select(db.syncCursors).get(), isEmpty);

    await seedCursor();
    await LocalDataService(db, cloud, state).wipeEverything();
    expect(await db.select(db.syncCursors).get(), isEmpty);
  });

  test('database opnieuw aangemaakt: het serveraccount wordt vergeten, niet gewist',
      () async {
    final dir = await Directory.systemTemp.createTemp('rfm_pull_test');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/t.sqlite');
    var recreated = 0;

    final first = AppDatabase(await openEncryptedFile(file, _keyA,
        onRecreated: () async => recreated++));
    await first.customStatement('SELECT 1');
    await first.close();
    expect(recreated, 0);

    final second = AppDatabase(await openEncryptedFile(file, _keyB,
        onRecreated: () async => recreated++));
    addTearDown(second.close);
    await second.customStatement('SELECT 1');
    expect(recreated, 1);
  });
}
