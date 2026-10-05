import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/data/repositories/routine_repository.dart';
import 'package:rest4more/data/sync/sync_engine.dart';
import 'package:rest4more/data/sync/sync_scheduler.dart';

import 'sync_engine_test.dart' show FakeRemote;
import 'test_support.dart';

void main() {
  late AppDatabase db;
  late FakeRemote remote;
  late SyncScheduler scheduler;

  setUp(() async {
    db = memoryDb();
    remote = FakeRemote();
    await ProfileRepository(db).recordCloudSyncConsent(DateTime.now());
    scheduler = SyncScheduler(
      db,
      SyncEngine(db, remote),
      debounce: const Duration(milliseconds: 50),
    );
  });
  tearDown(() async {
    await scheduler.dispose();
    await db.close();
  });

  Future<void> settle() => Future.delayed(const Duration(milliseconds: 300));

  test('pusht bij het starten', () async {
    scheduler.start();
    await settle();
    expect(remote.tables, contains('profiles'));
    expect(scheduler.lastResult?.ok, isTrue);
  });

  test('pusht na een lokale wijziging, gebundeld', () async {
    scheduler.start();
    await settle();
    remote.calls.clear();

    final repo = RoutineRepository(db);
    await repo.create(mode: 'focus', name: 'a');
    await repo.create(mode: 'focus', name: 'b');
    await settle();

    expect(remote.rowsOf('routines'), hasLength(2));
    expect(remote.calls.where((c) => c.$1 == 'routines'), hasLength(1));
  });

  test('stopt na dispose', () async {
    scheduler.start();
    await settle();
    await scheduler.dispose();
    remote.calls.clear();
    await RoutineRepository(db).create(mode: 'focus', name: 'a');
    await settle();
    expect(remote.calls, isEmpty);
  });
}
