import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/data/repositories/routine_repository.dart';
import 'package:rest4more/data/sync/sync_engine.dart';
import 'package:rest4more/data/sync/sync_scheduler.dart';

import 'sync_engine_test.dart' show FakeRemote;
import 'test_support.dart';

class MemoryStateStore implements SyncStateStore {
  String? date;

  @override
  Future<String?> lastSuccessDate() async => date;

  @override
  Future<void> saveSuccessDate(String date) async => this.date = date;
}

void main() {
  late AppDatabase db;
  late FakeRemote remote;
  late MemoryStateStore store;
  late TestClock clock;
  late SyncScheduler scheduler;

  Future<void> consent() =>
      ProfileRepository(db).recordCloudSyncConsent(DateTime.now());

  setUp(() {
    db = memoryDb();
    remote = FakeRemote();
    store = MemoryStateStore();
    clock = TestClock(DateTime(2026, 3, 2, 9));
    scheduler = SyncScheduler(
      SyncEngine(db, remote),
      store,
      now: clock.call,
      retryInterval: const Duration(milliseconds: 50),
    );
  });
  tearDown(() async {
    scheduler.dispose();
    await db.close();
  });

  Future<void> settle() => Future.delayed(const Duration(milliseconds: 250));

  test('pusht bij openen en onthoudt de dag', () async {
    await consent();
    await scheduler.maybePush();
    expect(remote.tables, contains('profiles'));
    expect(store.date, '2026-03-02');
  });

  test('pusht vandaag maar een keer, ook na nieuwe wijzigingen', () async {
    await consent();
    await scheduler.maybePush();
    remote.calls.clear();

    await RoutineRepository(db).create(mode: 'focus', name: 'a');
    await scheduler.maybePush();
    await scheduler.maybePush();
    expect(remote.calls, isEmpty);
  });

  test('de volgende dag wordt er weer gepusht', () async {
    await consent();
    await scheduler.maybePush();
    await RoutineRepository(db).create(mode: 'focus', name: 'a');
    remote.calls.clear();

    clock.current = DateTime(2026, 3, 3, 8);
    await scheduler.maybePush();
    expect(remote.rowsOf('routines'), hasLength(1));
    expect(store.date, '2026-03-03');
  });

  test('bij een fout wordt het later die dag opnieuw geprobeerd', () async {
    await consent();
    remote.failWith = Exception('offline');
    await scheduler.maybePush();
    expect(store.date, isNull);
    expect(scheduler.lastResult?.ok, isFalse);

    remote.failWith = null;
    await settle();
    expect(store.date, '2026-03-02');
    expect(scheduler.lastResult?.ok, isTrue);
  });

  test('openen terwijl het vandaag mislukt was probeert het opnieuw', () async {
    await consent();
    remote.failWith = Exception('offline');
    await scheduler.maybePush();
    scheduler.dispose();

    // Nieuwe start van de app dezelfde dag, nu met netwerk.
    remote.failWith = null;
    final restarted = SyncScheduler(
      SyncEngine(db, remote),
      store,
      now: clock.call,
    );
    addTearDown(restarted.dispose);
    await restarted.maybePush();
    expect(store.date, '2026-03-02');
  });

  test('zonder toestemming gebeurt er niets en telt de dag niet', () async {
    await scheduler.maybePush();
    expect(remote.calls, isEmpty);
    expect(store.date, isNull);
    expect(scheduler.lastResult?.skippedNoConsent, isTrue);

    await consent();
    await scheduler.maybePush();
    expect(store.date, '2026-03-02');
  });

  test('na dispose wordt er niet meer geprobeerd', () async {
    await consent();
    remote.failWith = Exception('offline');
    await scheduler.maybePush();
    scheduler.dispose();
    remote.failWith = null;
    await settle();
    expect(store.date, isNull);
  });
}
