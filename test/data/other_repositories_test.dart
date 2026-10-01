import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/converters.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/database/local_types.dart';
import 'package:rest4more/data/repositories/accessory_repository.dart';
import 'package:rest4more/data/repositories/block_profile_repository.dart';
import 'package:rest4more/data/repositories/entitlement_repository.dart';
import 'package:rest4more/data/repositories/local_notification_store.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/data/repositories/repository_support.dart';
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

  group('AccessoryRepository', () {
    test('dubbele token-hash wordt geweigerd', () async {
      final repo = AccessoryRepository(db, now: clock.call);
      final hash = AccessoryRepository.hashToken('abc');
      await repo.pairCard(tokenHash: hash, label: 'Kaart 1');
      await expectLater(
        repo.pairCard(tokenHash: hash, label: 'Kaart 2'),
        throwsA(isA<DuplicateTokenHashError>()),
      );
      expect(await db.select(db.accessories).get(), hasLength(1));
    });

    test('hashToken is stabiel en geeft nooit de ruwe token terug', () {
      const raw = '04:A2:2B:1C';
      final hash = AccessoryRepository.hashToken(raw);
      expect(AccessoryRepository.hashToken(raw), hash);
      expect(hash, isNot(contains(raw)));
      expect(hash, isNot(raw));
      expect(hash, hasLength(64));
      expect(AccessoryRepository.hashToken('anders'), isNot(hash));
      // Bekende SHA-256 van "abc".
      expect(
        AccessoryRepository.hashToken('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('verloren en ingetrokken kaart', () async {
      final repo = AccessoryRepository(db, now: clock.call);
      final card = await repo.pairCard(tokenHash: 'h', label: 'Kaart');
      expect(card.kind, AccessoryKind.card);
      expect(card.status, AccessoryStatus.active);
      expect(card.pairedAt, isNotNull);
      await repo.markLost(card.id);
      expect((await repo.watchAll().first).single.status, AccessoryStatus.lost);
      await repo.retire(card.id);
      expect(
          (await repo.watchAll().first).single.status, AccessoryStatus.retired);
      await expectLater(repo.retire('nee'), throwsA(isA<RowNotFoundError>()));
    });
  });

  group('ProfileRepository', () {
    test('een profielrij, aangemaakt bij eerste gebruik', () async {
      final repo = ProfileRepository(db, now: clock.call);
      expect(await db.select(db.profiles).get(), isEmpty);
      final first = await repo.get();
      final second = await repo.get();
      expect(second.id, first.id);
      expect(await db.select(db.profiles).get(), hasLength(1));
      expect((await repo.watch().first).id, first.id);
    });

    test('intake kan hervatten en afronden', () async {
      final repo = ProfileRepository(db, now: clock.call);
      await repo.saveIntakeStep(2,
          answers: const ProfileDraft(
            primaryGoal: PrimaryGoal.phone,
            bedtimeMinutes: 23 * 60,
          ));
      var profile = await repo.get();
      expect(profile.intakeStep, 2);
      expect(profile.primaryGoal, PrimaryGoal.phone);
      expect(profile.intakeCompletedAt, isNull);

      await repo.upsert(const ProfileDraft(displayName: 'Sam'));
      profile = await repo.get();
      expect(profile.displayName, 'Sam');
      expect(profile.primaryGoal, PrimaryGoal.phone, reason: 'blijft staan');

      await repo.completeIntake();
      expect((await repo.get()).intakeCompletedAt, isNotNull);
    });

    test('meldingen en toestemming', () async {
      final repo = ProfileRepository(db, now: clock.call);
      await repo.setNotification(enabled: true, minutes: 20 * 60 + 30);
      final profile = await repo.get();
      expect(profile.notifyProgramme, isTrue);
      expect(profile.notifyTimeMinutes, 1230);
      await expectLater(
        repo.setNotification(enabled: true, minutes: 1440),
        throwsA(isA<InvalidValueError>()),
      );
      final consent = DateTime.utc(2026, 3, 2, 12);
      await repo.recordCloudSyncConsent(consent);
      expect((await repo.get()).cloudSyncConsentAt, consent);
      await repo.recordCloudSyncConsent(null);
      expect((await repo.get()).cloudSyncConsentAt, isNull);
    });
  });

  group('RoutineRepository', () {
    test('stappen en schema', () async {
      final repo = RoutineRepository(db, now: clock.call);
      final routine = await repo.create(mode: 'evening', name: 'Avond');
      await repo.setSteps(routine.id, const [
        RoutineStepData(title: 'Lezen', durationMin: 10),
      ]);
      await repo.setSchedule(
        routine.id,
        WeekdayMask.fromWeekdays({1, 3, 5}),
        21 * 60,
        true,
      );
      final row = (await repo.watchAll().first).single;
      expect(
          row.steps, [const RoutineStepData(title: 'Lezen', durationMin: 10)]);
      expect(WeekdayMask(row.daysMask).toWeekdays(), {1, 3, 5});
      expect(row.startMinutes, 1260);
      expect(row.autoStart, isTrue);
      await expectLater(
        repo.setSchedule(routine.id, WeekdayMask.none, 2000, false),
        throwsA(isA<InvalidValueError>()),
      );
    });

    test('bewerken van een verwijderde routine geeft RowNotFoundError',
        () async {
      final repo = RoutineRepository(db, now: clock.call);
      final routine = await repo.create(mode: 'focus', name: 'x');
      await repo.softDelete(routine.id);
      await expectLater(
        repo.update(routine.id, name: 'y'),
        throwsA(isA<RowNotFoundError>()),
      );
    });
  });

  group('BlockProfileRepository', () {
    test('items en iOS-selectie', () async {
      final repo = BlockProfileRepository(db, now: clock.call);
      final store = IosSelectionStore(db);
      final profile = await repo.create(name: 'Studie');
      await repo.setItems(profile.id, const [
        BlockItemData(kind: BlockItemKind.url, value: 'example.com'),
      ]);
      expect((await repo.watchAll().first).single.items, hasLength(1));

      expect(await store.get(profile.id), isNull);
      await store.save(profile.id, Uint8List.fromList([1, 2, 3]));
      await store.save(profile.id, Uint8List.fromList([4]));
      expect(await store.get(profile.id), [4]);

      await repo.softDelete(profile.id);
      expect(await store.get(profile.id), isNull);
    });
  });

  group('LocalNotificationStore', () {
    test('vervangen, annuleren en openen', () async {
      final store = LocalNotificationStore(db);
      PlannedEntry entry(int id, int minutes) => PlannedEntry(
            osNotificationId: id,
            kind: NotificationKind.programme,
            firesOn: DateTime(2026, 3, 3),
            firesAtMinutes: minutes,
          );
      await store.replaceAll([entry(1, 600), entry(2, 540)]);
      var scheduled = await store.watchScheduled().first;
      expect(scheduled.map((e) => e.osNotificationId), [2, 1]);
      expect(scheduled.first.firesOn, '2026-03-03');

      await store.replaceAll([entry(3, 60)]);
      scheduled = await store.watchScheduled().first;
      expect(scheduled.map((e) => e.osNotificationId), [3]);

      await store.markOpened(scheduled.single.id);
      expect(await store.watchScheduled().first, isEmpty);

      await store.replaceAll([entry(4, 60)]);
      await store.cancelAll();
      expect(await store.watchScheduled().first, isEmpty);
      expect((await db.select(db.localNotifications).getSingle()).status,
          NotificationStatus.cancelled);
    });
  });

  group('EntitlementRepository', () {
    Entitlement entitlement(
      String id, {
      EntitlementStatus status = EntitlementStatus.active,
      DateTime? endsAt,
    }) =>
        Entitlement(
          id: id,
          updatedAt: clock.current.toUtc(),
          dirty: true,
          feature: 'extra',
          source: EntitlementSource.grant,
          status: status,
          startsAt: DateTime.utc(2026, 1, 1),
          endsAt: endsAt,
        );

    test('alleen actieve, niet verlopen rechten', () async {
      final repo = EntitlementRepository(db, now: clock.call);
      await repo.replaceFromServer([
        entitlement('a'),
        entitlement('b', endsAt: DateTime.utc(2027, 1, 1)),
        entitlement('c', endsAt: DateTime.utc(2026, 1, 2)),
        entitlement('d', status: EntitlementStatus.revoked),
        entitlement('e', status: EntitlementStatus.expired),
      ]);
      final active = await repo.watchActive().first;
      expect(active.map((e) => e.id).toSet(), {'a', 'b'});
      expect(active.every((e) => !e.dirty), isTrue);
    });

    test('rijen die de server niet meer noemt verdwijnen zacht', () async {
      final repo = EntitlementRepository(db, now: clock.call);
      await repo.replaceFromServer([entitlement('a'), entitlement('b')]);
      await repo.replaceFromServer([entitlement('b')]);
      expect((await repo.watchActive().first).map((e) => e.id), ['b']);
      final all = await db.select(db.entitlements).get();
      expect(all, hasLength(2));
      expect(all.firstWhere((e) => e.id == 'a').deletedAt, isNotNull);
      expect(all.every((e) => !e.dirty), isTrue);
    });
  });
}
