import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/data/repositories/routine_repository.dart';
import 'package:rest4more/data/sync/sync_engine.dart';

import 'sync_engine_test.dart' show FakeRemote;
import 'sync_scheduler_test.dart' show MemoryStateStore;
import 'test_support.dart';

void main() {
  late AppDatabase db;
  late FakeRemote remote;
  late MemoryStateStore state;
  late SyncEngine engine;

  setUp(() async {
    db = memoryDb();
    remote = FakeRemote();
    state = MemoryStateStore();
    engine = SyncEngine(db, remote, state: state);
    await ProfileRepository(db).recordCloudSyncConsent(DateTime.now());
    await RoutineRepository(db).create(mode: 'focus', name: 'Avond');
  });
  tearDown(() => db.close());

  test('elke geslaagde push laat de server weten dat het account leeft',
      () async {
    await engine.pushDirty();
    expect(remote.activity, 1);
    await engine.pushDirty();
    expect(remote.activity, 2);
  });

  test('geen hartslag bij een mislukte of overgeslagen push', () async {
    remote.failWith = Exception('offline');
    await engine.pushDirty();
    expect(remote.activity, 0);

    final noConsent = memoryDb();
    addTearDown(noConsent.close);
    await SyncEngine(noConsent, remote, state: state).pushDirty();
    expect(remote.activity, 0);
  });

  test('een mislukte hartslag laat de push niet mislukken', () async {
    remote.activityFails = Exception('functie ontbreekt');
    final result = await engine.pushDirty();
    expect(result.ok, isTrue);
    expect(remote.rowsOf('routines'), hasLength(1));
  });

  test('hetzelfde account: niet opnieuw alles versturen', () async {
    await engine.pushDirty();
    expect(state.userId, 'user-1');
    remote.calls.clear();
    await engine.pushDirty();
    expect(remote.calls, isEmpty);
  });

  test('een nieuw account (oude is opgeruimd): alles gaat opnieuw mee',
      () async {
    await engine.pushDirty();
    remote.calls.clear();

    remote.userId = 'user-2';
    final result = await engine.pushDirty();
    expect(result.ok, isTrue);
    expect(remote.rowsOf('routines'), hasLength(1));
    expect(remote.rowsOf('profiles'), hasLength(1));
    expect(state.userId, 'user-2');
  });

  test('eerste keer: account onthouden zonder alles opnieuw te sturen',
      () async {
    await engine.pushDirty();
    remote.calls.clear();
    expect(state.userId, 'user-1');
    await engine.pushDirty();
    expect(remote.calls, isEmpty);
  });
}
