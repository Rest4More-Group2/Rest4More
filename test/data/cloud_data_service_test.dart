import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/data/repositories/routine_repository.dart';
import 'package:rest4more/data/sync/cloud_data_service.dart';
import 'package:rest4more/data/sync/sync_engine.dart';
import 'package:rest4more/data/sync/sync_remote.dart';

import 'sync_engine_test.dart' show FakeRemote;
import 'sync_scheduler_test.dart' show MemoryStateStore;
import 'test_support.dart';

void main() {
  late AppDatabase db;
  late FakeRemote remote;
  late MemoryStateStore state;
  late ProfileRepository profiles;
  late CloudDataService service;

  setUp(() async {
    db = memoryDb();
    remote = FakeRemote();
    state = MemoryStateStore()..date = '2026-03-02';
    profiles = ProfileRepository(db);
    service = CloudDataService(db, remote, state, profiles);
    await profiles.recordCloudSyncConsent(DateTime.now());
    await RoutineRepository(db).create(mode: 'focus', name: 'Avond');
  });
  tearDown(() => db.close());

  Future<int> dirtyCount() async {
    var total = 0;
    for (final t in ['profiles', 'routines']) {
      final rows = await db
          .customSelect('SELECT COUNT(*) AS c FROM $t WHERE dirty = 1')
          .get();
      total += rows.single.read<int>('c');
    }
    return total;
  }

  test('export geeft de gegevens van de server als leesbare json', () async {
    remote.exportData = {
      'user_id': 'u1',
      'routines': [
        {'name': 'Avond'},
      ],
    };
    final json = await service.exportAsJson();
    expect(json, contains('\n  '), reason: 'ingesprongen');
    expect(jsonDecode(json), remote.exportData);
    expect(remote.signedIn, 1);
  });

  test('export zonder server geeft een fout', () async {
    final offline = CloudDataService(
        db, const UnavailableSyncRemote(), state, profiles);
    await expectLater(
        offline.exportAsJson(), throwsA(isA<SyncUnavailableError>()));
  });

  test('verwijderen wist de server, zet sync uit en markeert alles dirty',
      () async {
    await SyncEngine(db, remote).pushDirty();
    expect(await dirtyCount(), 0);
    await db.customStatement('''INSERT INTO entitlements
      (id, updated_at, dirty, feature, source, status, starts_at)
      VALUES ('e1', '2026-03-02T10:00:00.000Z', 0, 'extra', 'grant', 'active',
      '2026-01-01T00:00:00.000Z')''');

    await service.deleteCloudData();

    expect(remote.deleted, 1);
    expect((await profiles.get()).cloudSyncConsentAt, isNull);
    expect(state.date, isNull);
    expect(await dirtyCount(), 2, reason: 'lokale data kan opnieuw uploaden');
    expect(await db.select(db.entitlements).get(), isEmpty);
    expect(await db.select(db.routines).get(), hasLength(1),
        reason: 'lokale data blijft');
  });

  test('na verwijderen wordt er niets meer verstuurd tot nieuwe toestemming',
      () async {
    await service.deleteCloudData();
    remote.calls.clear();
    final result = await SyncEngine(db, remote).pushDirty();
    expect(result.skippedNoConsent, isTrue);
    expect(remote.calls, isEmpty);

    await profiles.recordCloudSyncConsent(DateTime.now());
    await SyncEngine(db, remote).pushDirty();
    expect(remote.rowsOf('routines'), hasLength(1));
  });

  test('als verwijderen op de server mislukt verandert lokaal niets', () async {
    remote.failWith = Exception('offline');
    await expectLater(service.deleteCloudData(), throwsException);
    expect((await profiles.get()).cloudSyncConsentAt, isNotNull);
    expect(state.date, '2026-03-02');
  });
}
