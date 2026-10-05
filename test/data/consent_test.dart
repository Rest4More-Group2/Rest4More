import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/repositories/consent_repository.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/data/sync/sync_engine.dart';

import 'sync_engine_test.dart' show FakeRemote;
import 'test_support.dart';

void main() {
  late AppDatabase db;
  late TestClock clock;
  late ProfileRepository profiles;
  late ConsentRepository consents;

  setUp(() {
    db = memoryDb();
    clock = TestClock();
    profiles = ProfileRepository(db, now: clock.call);
    consents = ConsentRepository(db, now: clock.call);
  });
  tearDown(() => db.close());

  group('leeftijdsgrens', () {
    test('onbekende leeftijd: toestemming wordt geweigerd', () async {
      await expectLater(
        profiles.recordCloudSyncConsent(clock.current),
        throwsA(isA<CloudSyncNotAllowedError>()),
      );
      expect((await profiles.get()).cloudSyncConsentAt, isNull);
      expect(await db.select(db.consentRecords).get(), isEmpty);
    });

    test('onder de 16: toestemming wordt geweigerd', () async {
      await profiles.upsert(const ProfileDraft(ageBand: AgeBand.under16));
      await expectLater(
        profiles.recordCloudSyncConsent(clock.current),
        throwsA(isA<CloudSyncNotAllowedError>()),
      );
    });

    test('16 en ouder: toegestaan', () async {
      for (final band in [
        AgeBand.age16To17,
        AgeBand.age18To24,
        AgeBand.age25To39,
        AgeBand.age40To54,
        AgeBand.age55Plus,
      ]) {
        expect(ProfileRepository.isCloudSyncAllowedFor(band), isTrue);
      }
      for (final band in [AgeBand.under16, AgeBand.unknown, null]) {
        expect(ProfileRepository.isCloudSyncAllowedFor(band), isFalse);
      }
    });

    test('intrekken mag altijd, ook bij onbekende leeftijd', () async {
      await profiles.recordCloudSyncConsent(null);
      expect((await consents.latest(ConsentPurpose.cloudSync))?.status,
          ConsentStatus.withdrawn);
    });

    test('leeftijd daalt onder 16 terwijl er toestemming is: ingetrokken',
        () async {
      await grantConsent(db, now: clock.call);
      expect((await profiles.get()).cloudSyncConsentAt, isNotNull);
      clock.advance();
      await profiles.upsert(const ProfileDraft(ageBand: AgeBand.under16));
      expect((await profiles.get()).cloudSyncConsentAt, isNull);
      final last = await consents.latest(ConsentPurpose.cloudSync);
      expect(last?.status, ConsentStatus.withdrawn);
    });

    test('ook via de intake wordt toestemming ingetrokken', () async {
      await grantConsent(db, now: clock.call);
      clock.advance();
      await profiles.saveIntakeStep(1,
          answers: const ProfileDraft(ageBand: AgeBand.under16));
      expect((await profiles.get()).cloudSyncConsentAt, isNull);
    });

    test('de engine verstuurt niets voor onder de 16, ook met oude toestemming',
        () async {
      await grantConsent(db, now: clock.call);
      // Simuleer een rij waarin toestemming nog staat maar de leeftijd laag is.
      await db.customStatement("UPDATE profiles SET age_band = 'under16'");
      final remote = FakeRemote();
      final result = await SyncEngine(db, remote).pushDirty();
      expect(result.skippedAgeGate, isTrue);
      expect(result.ok, isFalse);
      expect(remote.calls, isEmpty);
      expect(remote.signedIn, 0);
    });

    test('onbekende toekomstige leeftijdswaarde wordt ook geblokkeerd',
        () async {
      await grantConsent(db, now: clock.call);
      await db.customStatement("UPDATE profiles SET age_band = 'future_value'");
      final result = await SyncEngine(db, FakeRemote()).pushDirty();
      expect(result.skippedAgeGate, isTrue);
    });
  });

  group('bewijs van toestemming', () {
    test('toestemming en intrekken worden als rijen vastgelegd', () async {
      await profiles.upsert(const ProfileDraft(ageBand: AgeBand.age25To39));
      await profiles.recordCloudSyncConsent(clock.current);
      clock.advance(const Duration(days: 1));
      await profiles.recordCloudSyncConsent(null);

      final all = await consents.watchAll().first;
      expect(all.map((r) => r.status),
          [ConsentStatus.withdrawn, ConsentStatus.granted]);
      expect(all.every((r) => r.purpose == ConsentPurpose.cloudSync), isTrue);
      expect(all.every((r) => r.policyVersion == currentCloudSyncPolicyVersion),
          isTrue);
      expect(all.every((r) => r.dirty), isTrue);
      expect(all.last.recordedAt.isUtc, isTrue);
    });

    test('de versie van de tekst wordt bewaard', () async {
      await profiles.upsert(const ProfileDraft(ageBand: AgeBand.age25To39));
      await profiles.recordCloudSyncConsent(clock.current,
          policyVersion: '2026-01-oud');
      expect((await consents.latest(ConsentPurpose.cloudSync))?.policyVersion,
          '2026-01-oud');
    });

    test('needsReconsent: nooit, oude versie, huidige versie, ingetrokken',
        () async {
      expect(await consents.needsReconsent(ConsentPurpose.cloudSync), isTrue);

      await profiles.upsert(const ProfileDraft(ageBand: AgeBand.age25To39));
      await profiles.recordCloudSyncConsent(clock.current,
          policyVersion: 'oud');
      expect(await consents.needsReconsent(ConsentPurpose.cloudSync), isTrue);

      clock.advance();
      await profiles.recordCloudSyncConsent(clock.current);
      expect(await consents.needsReconsent(ConsentPurpose.cloudSync), isFalse);

      clock.advance();
      await profiles.recordCloudSyncConsent(null);
      expect(await consents.needsReconsent(ConsentPurpose.cloudSync), isTrue);
    });

    test('consent_records gaan mee naar de server, voor de rest', () async {
      await grantConsent(db, now: clock.call);
      final remote = FakeRemote();
      await SyncEngine(db, remote).pushDirty();
      expect(remote.tables.first, 'profiles');
      final row = remote.rowsOf('consent_records').single;
      expect(row['status'], 'granted');
      expect(row['purpose'], 'cloud_sync');
      expect(row['policy_version'], currentCloudSyncPolicyVersion);
      expect((row['recorded_at'] as String).endsWith('Z'), isTrue);
    });
  });
}
