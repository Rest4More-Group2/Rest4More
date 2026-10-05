import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/repositories/block_profile_repository.dart';
import 'package:rest4more/data/repositories/consent_repository.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/data/repositories/routine_repository.dart';
import 'package:rest4more/data/sync/cloud_data_service.dart';
import 'package:rest4more/data/sync/local_data_service.dart';
import 'package:rest4more/data/sync/sync_engine.dart';
import 'package:rest4more/data/sync/sync_remote.dart';
import 'package:rest4more/data/sync/sync_scheduler.dart';

import 'sync_engine_test.dart' show FakeRemote;
import 'sync_scheduler_test.dart' show MemoryStateStore;
import 'test_support.dart';

void main() {
  late AppDatabase db;
  late FakeRemote remote;
  late MemoryStateStore state;
  late ProfileRepository profiles;
  late CloudDataService cloud;

  setUp(() async {
    db = memoryDb();
    remote = FakeRemote();
    state = MemoryStateStore();
    profiles = ProfileRepository(db);
    cloud = CloudDataService(db, remote, state, profiles);
    await grantConsent(db);
    await RoutineRepository(db).create(mode: 'focus', name: 'Avond');
    // Een gelukte push: er staat nu data in de cloud en het account is bekend.
    await SyncEngine(db, remote, state: state).pushDirty();
  });
  tearDown(() => db.close());

  Future<int> dirtyRoutines() async => (await db
          .customSelect('SELECT COUNT(*) AS c FROM routines WHERE dirty = 1')
          .getSingle())
      .read<int>('c');

  group('openstaande verwijdering van de cloud', () {
    test('met toestemming is er niets te doen', () async {
      expect(await cloud.completePendingErasure(), isFalse);
      expect(remote.deleted, 0);
    });

    test('zonder serveraccount is er niets te doen', () async {
      state.userId = null;
      await profiles.recordCloudSyncConsent(null);
      expect(await cloud.completePendingErasure(), isFalse);
      expect(remote.deleted, 0);
    });

    test('toestemming ingetrokken met account: de cloud wordt gewist', () async {
      await profiles.recordCloudSyncConsent(null);
      expect(await cloud.completePendingErasure(), isTrue);
      expect(remote.deleted, 1);
      expect(state.userId, isNull);
      expect(await dirtyRoutines(), 1, reason: 'lokaal opnieuw te uploaden');
      // Is het gedaan, dan is er niets meer open.
      expect(await cloud.completePendingErasure(), isFalse);
      expect(remote.deleted, 1);
    });

    test('geen dubbele intrekking in het bewijs van toestemming', () async {
      await profiles.recordCloudSyncConsent(null);
      await cloud.completePendingErasure();
      final withdrawn = (await db.select(db.consentRecords).get())
          .where((r) => r.status == ConsentStatus.withdrawn);
      expect(withdrawn, hasLength(1));
    });

    test('server onbereikbaar: blijft openstaan en lukt later', () async {
      await profiles.recordCloudSyncConsent(null);
      remote.failWith = Exception('offline');
      await expectLater(cloud.completePendingErasure(), throwsException);
      expect(state.userId, isNotNull);
      expect(remote.deleted, 0);

      remote.failWith = null;
      expect(await cloud.completePendingErasure(), isTrue);
      expect(remote.deleted, 1);
      expect(state.userId, isNull);
    });

    test('withdrawConsent trekt in en wist meteen', () async {
      await cloud.withdrawConsent();
      expect((await profiles.get()).cloudSyncConsentAt, isNull);
      expect(remote.deleted, 1);
    });

    test('withdrawConsent offline: toestemming is wel ingetrokken', () async {
      remote.failWith = Exception('offline');
      await cloud.withdrawConsent();
      expect((await profiles.get()).cloudSyncConsentAt, isNull);
      expect(state.userId, isNotNull, reason: 'verwijdering staat open');

      remote.failWith = null;
      await cloud.completePendingErasure();
      expect(remote.deleted, 1);
    });

    test('leeftijd onder 16 wist ook de cloud', () async {
      await profiles.upsert(const ProfileDraft(ageBand: AgeBand.under16));
      expect((await profiles.get()).cloudSyncConsentAt, isNull);
      expect(await cloud.completePendingErasure(), isTrue);
      expect(remote.deleted, 1);
    });

    test('het account is al weg: lokaal opnieuw klaarzetten zonder serveraanroep',
        () async {
      await profiles.recordCloudSyncConsent(null);
      remote.userId = null;
      expect(await cloud.completePendingErasure(), isTrue);
      expect(remote.deleted, 0);
      expect(state.userId, isNull);
      expect(await dirtyRoutines(), 1);
    });

    test('zonder Supabase wordt er niets gewist of vergeten', () async {
      await profiles.recordCloudSyncConsent(null);
      final offline = CloudDataService(
          db, const UnavailableSyncRemote(), state, profiles);
      expect(await offline.completePendingErasure(), isFalse);
      expect(state.userId, isNotNull);
    });

    test('de scheduler maakt het eerst af, ook als er vandaag al gepusht is',
        () async {
      state.date = '2026-03-02';
      await profiles.recordCloudSyncConsent(null);
      final scheduler = SyncScheduler(
        SyncEngine(db, remote, state: state),
        state,
        now: () => DateTime(2026, 3, 2, 12),
        beforePush: cloud.completePendingErasure,
      );
      addTearDown(scheduler.dispose);
      await scheduler.maybePush();
      expect(remote.deleted, 1);
    });

    test('de scheduler probeert opnieuw als het wissen mislukt', () async {
      await profiles.recordCloudSyncConsent(null);
      remote.failWith = Exception('offline');
      final scheduler = SyncScheduler(
        SyncEngine(db, remote, state: state),
        state,
        retryInterval: const Duration(milliseconds: 50),
        beforePush: cloud.completePendingErasure,
      );
      addTearDown(scheduler.dispose);
      await scheduler.maybePush();
      expect(remote.deleted, 0);

      remote.failWith = null;
      await Future.delayed(const Duration(milliseconds: 250));
      expect(remote.deleted, 1);
    });
  });

  group('lokaal exporteren en wissen', () {
    late LocalDataService local;

    setUp(() => local = LocalDataService(db, cloud, state));

    test('export bevat alle tabellen en gaat niet over lege plekken', () async {
      final block = await BlockProfileRepository(db).create(name: 'Studie');
      await IosSelectionStore(db)
          .save(block.id, Uint8List.fromList([1, 2, 3]));
      final json = jsonDecode(await local.exportAsJson()) as Map;

      expect(json['schema_version'], 2);
      for (final table in [
        'profiles',
        'consent_records',
        'routines',
        'block_profiles',
        'ios_selections',
        'accessories',
        'focus_sessions',
        'programme_enrollments',
        'programme_days',
        'local_notifications',
        'entitlements',
      ]) {
        expect(json.containsKey(table), isTrue, reason: table);
      }
      expect((json['routines'] as List).single['name'], 'Avond');
      expect((json['ios_selections'] as List).single['selection_blob'],
          base64Encode([1, 2, 3]));
      expect((json['consent_records'] as List), isNotEmpty);
    });

    test('wissen maakt alle tabellen leeg en trekt de cloud in', () async {
      final block = await BlockProfileRepository(db).create(name: 'Studie');
      await IosSelectionStore(db).save(block.id, Uint8List.fromList([9]));

      final result = await local.wipeEverything();

      expect(result.cloudErasurePending, isFalse);
      expect(remote.deleted, 1);
      for (final table in [
        'routines',
        'block_profiles',
        'ios_selections',
        'consent_records',
        'accessories',
        'focus_sessions',
        'programme_days',
        'local_notifications',
        'entitlements',
      ]) {
        final rows = await db.customSelect('SELECT 1 FROM $table').get();
        expect(rows, isEmpty, reason: table);
      }
      expect(state.date, isNull);
      expect(state.userId, isNull);
      // Een nieuw profiel zonder toestemming wordt weer vanzelf aangemaakt.
      expect((await profiles.get()).cloudSyncConsentAt, isNull);
    });

    test('wissen zonder verbinding: lokaal gewist, cloud blijft openstaan',
        () async {
      remote.failWith = Exception('offline');
      final result = await local.wipeEverything();

      expect(result.cloudErasurePending, isTrue);
      expect(await db.select(db.routines).get(), isEmpty);
      expect(state.userId, isNotNull);

      // Later, met verbinding, wordt de cloud alsnog gewist.
      remote.failWith = null;
      expect(await cloud.completePendingErasure(), isTrue);
      expect(remote.deleted, 1);
      expect(state.userId, isNull);
    });

    test('wissen zonder cloudaccount raakt de server niet', () async {
      state.userId = null;
      final result = await local.wipeEverything();
      expect(result.cloudErasurePending, isFalse);
      expect(remote.deleted, 0);
      expect(await db.select(db.routines).get(), isEmpty);
    });

    test('consentbewijs voor het wissen bestaat nog tot het wissen', () async {
      expect(await ConsentRepository(db).latest(ConsentPurpose.cloudSync),
          isNotNull);
      await local.wipeEverything();
      expect(await ConsentRepository(db).latest(ConsentPurpose.cloudSync),
          isNull);
    });
  });
}
