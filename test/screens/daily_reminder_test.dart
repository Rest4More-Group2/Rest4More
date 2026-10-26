import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/notifications/daily_reminder_plan.dart';
import 'package:rest4more/data/notifications/notification_permission.dart';
import 'package:rest4more/data/notifications/reminder_service.dart';
import 'package:rest4more/data/repositories/local_notification_store.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/data/repositories/programme_repository.dart';
import 'package:rest4more/screens/app_shell.dart';
import 'package:rest4more/screens/profile_tab.dart';

import '../data/test_support.dart';
import 'onboarding_test_support.dart';

/// Een actief plan van 14 dagen met titels, beginnend op [start].
Future<String> _seedPlan(AppDatabase db, DateTime start,
    {DateTime Function()? now}) async {
  final programme = ProgrammeRepository(db, now: now ?? DateTime.now);
  final enrollment = await programme.enroll(
    contentVersion: 'v1',
    selection: const {'goal': 'phone'},
    startedOn: start,
  );
  await programme.createDays(enrollment.id, [
    for (var i = 1; i <= 14; i++)
      DaySeed(
        dayNumber: i,
        contentId: 'day-$i',
        scheduledFor: DateTime(start.year, start.month, start.day + i - 1),
        snapshot: {'title': 'Step $i'},
      ),
  ]);
  return enrollment.id;
}

Future<List<ProgrammeDay>> _days(AppDatabase db) =>
    db.select(db.programmeDays).get();

Future<void> _complete(AppDatabase db, int dayNumber, DateTime at) async {
  final day = (await _days(db)).firstWhere((d) => d.dayNumber == dayNumber);
  await ProgrammeRepository(db, now: () => at).markCompleted(day.id);
}

void main() {
  const eightPm = 20 * 60;

  group('planDailyReminders', () {
    late AppDatabase db;
    setUp(() => db = memoryDb());
    tearDown(() => db.close());

    test('één per dag op de gekozen tijd, vanaf vandaag als die nog komt',
        () async {
      await _seedPlan(db, DateTime(2026, 3, 2));
      final reminders = planDailyReminders(
        days: await _days(db),
        minutes: eightPm,
        now: DateTime(2026, 3, 2, 10),
      );

      expect(reminders, hasLength(reminderHorizonDays));
      expect(reminders.first.date, DateTime(2026, 3, 2));
      expect(reminders.every((r) => r.minutes == eightPm), isTrue);
      expect(reminders.map((r) => r.date).toSet(), hasLength(reminders.length),
          reason: 'nooit twee op een dag');
      expect(reminders.map((r) => r.id).toSet(), hasLength(reminders.length));
      expect(reminders.first.body, 'Day 1 of 14: Step 1');
    });

    test('tijd vandaag al voorbij: vanaf morgen', () async {
      await _seedPlan(db, DateTime(2026, 3, 2));
      final reminders = planDailyReminders(
        days: await _days(db),
        minutes: eightPm,
        now: DateTime(2026, 3, 2, 20, 0),
      );
      expect(reminders.first.date, DateTime(2026, 3, 3));
    });

    test('stap van vandaag al gedaan: niet vandaag, morgen de volgende stap',
        () async {
      await _seedPlan(db, DateTime(2026, 3, 2));
      await _complete(db, 1, DateTime(2026, 3, 2, 9));
      final reminders = planDailyReminders(
        days: await _days(db),
        minutes: eightPm,
        now: DateTime(2026, 3, 2, 10),
      );
      expect(reminders.first.date, DateTime(2026, 3, 3));
      expect(reminders.first.day, 2);
      expect(reminders.first.stepTitle, 'Step 2');
    });

    test('na gemiste dagen: de eerstvolgende stap die nog niet gedaan is',
        () async {
      await _seedPlan(db, DateTime(2026, 3, 2));
      await _complete(db, 1, DateTime(2026, 3, 2, 21));
      await _complete(db, 2, DateTime(2026, 3, 3, 21));
      final reminders = planDailyReminders(
        days: await _days(db),
        minutes: eightPm,
        now: DateTime(2026, 3, 10, 10),
      );
      expect(reminders.first.date, DateTime(2026, 3, 10));
      expect(reminders.every((r) => r.day == 3), isTrue);
    });

    test('plan begint morgen: de eerste herinnering ook', () async {
      await _seedPlan(db, DateTime(2026, 3, 3));
      final reminders = planDailyReminders(
        days: await _days(db),
        minutes: eightPm,
        now: DateTime(2026, 3, 2, 10),
      );
      expect(reminders.first.date, DateTime(2026, 3, 3));
    });

    test('alle stappen gedaan: geen herinneringen meer', () async {
      await _seedPlan(db, DateTime(2026, 3, 2));
      for (var i = 1; i <= 14; i++) {
        await _complete(db, i, DateTime(2026, 3, 1 + i, 21));
      }
      expect(
        planDailyReminders(
          days: await _days(db),
          minutes: eightPm,
          now: DateTime(2026, 3, 20, 10),
        ),
        isEmpty,
      );
    });
  });

  group('ReminderService.sync', () {
    late AppDatabase db;
    late FakeReminderScheduler scheduler;
    late FakeNotificationPermission permission;
    final now = DateTime(2026, 3, 2, 10);

    ReminderService service() => ReminderService(
          ProfileRepository(db),
          permission,
          programme: ProgrammeRepository(db),
          scheduler: scheduler,
          store: LocalNotificationStore(db),
          now: () => now,
        );

    Future<List<LocalNotification>> rows() =>
        db.select(db.localNotifications).get();

    setUp(() async {
      db = memoryDb();
      scheduler = FakeReminderScheduler();
      permission =
          FakeNotificationPermission(NotificationPermissionStatus.granted);
      await _seedPlan(db, DateTime(2026, 3, 2));
      await ProfileRepository(db)
          .setNotification(enabled: true, minutes: eightPm);
    });
    tearDown(() => db.close());

    test('plant de herinneringen en houdt ze lokaal bij', () async {
      await service().sync();

      expect(scheduler.scheduled, hasLength(reminderHorizonDays));
      final stored = await rows();
      expect(stored, hasLength(reminderHorizonDays));
      expect(stored.every((r) => r.kind == NotificationKind.programme), isTrue);
      expect(
          stored.every((r) => r.status == NotificationStatus.scheduled), isTrue);
    });

    test('herinnering uit: alles weg', () async {
      await service().sync();
      await ProfileRepository(db).setNotification(enabled: false);
      await service().sync();

      expect(scheduler.scheduled, isEmpty);
      expect(scheduler.cancels, 1);
      expect((await rows()).every((r) => r.status != NotificationStatus.scheduled),
          isTrue);
    });

    test('meldingen niet toegestaan: niets gepland', () async {
      permission.current = NotificationPermissionStatus.blocked;
      await service().sync();
      expect(scheduler.scheduled, isEmpty);
      expect(scheduler.cancels, 1);
    });

    test('plan gepauzeerd of gestopt: niets gepland', () async {
      final programme = ProgrammeRepository(db);
      final enrollment = await programme.watchActiveEnrollment().first;
      await programme.pause(enrollment!.id);
      await service().sync();
      expect(scheduler.scheduled, isEmpty);

      await programme.stop(enrollment.id);
      await service().sync();
      expect(scheduler.scheduled, isEmpty);
    });

    test('toestemming onleesbaar: de planning blijft staan', () async {
      await service().sync();
      final throwing = ReminderService(
        ProfileRepository(db),
        _ThrowingPermission(),
        programme: ProgrammeRepository(db),
        scheduler: scheduler,
        store: LocalNotificationStore(db),
        now: () => now,
      );
      await throwing.sync();
      expect(scheduler.scheduled, hasLength(reminderHorizonDays));
      expect(scheduler.cancels, 0);
    });

    test('een geopende herinnering wordt bijgehouden', () async {
      await service().sync();
      final id = scheduler.scheduled.first.id;
      await service().markOpened(id);
      final row = (await rows()).firstWhere((r) => r.osNotificationId == id);
      expect(row.status, NotificationStatus.opened);
    });
  });

  group('Profiel: dagelijkse herinnering', () {
    screenTest('aanzetten vraagt eerst uitleg, daarna staat hij aan',
        (tester) async {
      final permission = FakeNotificationPermission(
        NotificationPermissionStatus.notDetermined,
        afterRequest: NotificationPermissionStatus.granted,
      );
      final db = await pumpScreen(tester, const ProfileTab(),
          permission: permission);
      await tester.pumpAndSettle();
      expect(find.text('Reminder time'), findsNothing);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('Allow notifications?'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(permission.requests, 1);
      final profile = await ProfileRepository(db).get();
      expect(profile.notifyProgramme, isTrue);
      expect(profile.notifyTimeMinutes, 22 * 60);
      expect(find.text('Reminder time'), findsOneWidget);
    });

    screenTest('geweigerd: de herinnering blijft uit', (tester) async {
      final permission = FakeNotificationPermission(
        NotificationPermissionStatus.notDetermined,
        afterRequest: NotificationPermissionStatus.blocked,
      );
      final db = await pumpScreen(tester, const ProfileTab(),
          permission: permission);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('No reminders for now'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect((await ProfileRepository(db).get()).notifyProgramme, isFalse);
      expect(find.text('Reminder time'), findsNothing);
    });

    screenTest('uitzetten haalt de geplande herinneringen weg', (tester) async {
      final db = memoryDb();
      addTearDown(db.close);
      await ProfileRepository(db)
          .setNotification(enabled: true, minutes: eightPm);
      final scheduler = FakeReminderScheduler();
      await pumpScreen(tester, const ProfileTab(),
          db: db, scheduler: scheduler);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final profile = await ProfileRepository(db).get();
      expect(profile.notifyProgramme, isFalse);
      expect(profile.notifyTimeMinutes, eightPm, reason: 'tijd blijft bewaard');
      expect(scheduler.cancels, greaterThan(0));
    });
  });

  group('Tikken op een herinnering', () {
    int selectedTab(WidgetTester tester) =>
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index!;

    screenTest('opent Today, ook vanaf een ander tabblad', (tester) async {
      final scheduler = FakeReminderScheduler();
      await pumpScreen(tester, const AppShell(), scheduler: scheduler);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(selectedTab(tester), 3);

      scheduler.tapController.add(20260302);
      await tester.pumpAndSettle();
      expect(selectedTab(tester), 0);
    });

    screenTest('app geopend vanuit een herinnering: die wordt bijgehouden',
        (tester) async {
      final db = memoryDb();
      addTearDown(db.close);
      await LocalNotificationStore(db).replaceAll([
        PlannedEntry(
          osNotificationId: 20260302,
          kind: NotificationKind.programme,
          firesOn: DateTime(2026, 3, 2),
          firesAtMinutes: eightPm,
        ),
      ]);
      // Zonder herinnering in het profiel: het plannen bij het openen zet
      // alleen geplande rijen op geannuleerd, een geopende blijft geopend.
      final scheduler = FakeReminderScheduler()..launchId = 20260302;
      await pumpScreen(tester, const AppShell(), db: db, scheduler: scheduler);
      await tester.pumpAndSettle();

      final rows = await tester.runAsync(
          () => db.select(db.localNotifications).get());
      expect(rows!.single.status, NotificationStatus.opened);
      expect(selectedTab(tester), 0);
    });
  });
}

class _ThrowingPermission extends NotificationPermission {
  @override
  Future<NotificationPermissionStatus> status() async =>
      throw StateError('kanaal weg');

  @override
  Future<NotificationPermissionStatus> request() => status();

  @override
  Future<bool> openSettings() async => false;
}
