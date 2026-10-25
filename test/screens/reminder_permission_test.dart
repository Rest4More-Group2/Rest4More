import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/notifications/notification_permission.dart';
import 'package:rest4more/data/notifications/reminder_service.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/screens/app_shell.dart';
import 'package:rest4more/screens/onboarding/reminder_screen.dart';

import '../data/test_support.dart';
import 'onboarding_test_support.dart';

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  screenTest('al toegestaan: geen uitleg en geen systeemvenster',
      (tester) async {
    final permission =
        FakeNotificationPermission(NotificationPermissionStatus.granted);
    final db = await pumpScreen(tester, const ReminderScreen(),
        permission: permission);
    await tapText(tester, 'Done');

    expect(find.text('Allow notifications?'), findsNothing);
    expect(permission.requests, 0);
    expect((await ProfileRepository(db).get()).notifyProgramme, isTrue);
    expect(find.byType(AppShell), findsOneWidget);
  });

  screenTest('Maybe later vraagt nooit om toestemming', (tester) async {
    final permission =
        FakeNotificationPermission(NotificationPermissionStatus.notDetermined);
    final db = await pumpScreen(tester, const ReminderScreen(),
        permission: permission);
    await tapText(tester, 'Maybe later');

    expect(permission.requests, 0);
    expect((await ProfileRepository(db).get()).notifyProgramme, isFalse);
    expect(find.byType(AppShell), findsOneWidget);
  });

  screenTest('herinnering uitgezet: Done vraagt niets', (tester) async {
    final permission =
        FakeNotificationPermission(NotificationPermissionStatus.notDetermined);
    final db = await pumpScreen(tester, const ReminderScreen(),
        permission: permission);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tapText(tester, 'Done');

    expect(permission.requests, 0);
    expect((await ProfileRepository(db).get()).notifyProgramme, isFalse);
  });

  screenTest('eerst uitleg, dan het systeem; toegestaan bewaart de herinnering',
      (tester) async {
    final permission = FakeNotificationPermission(
      NotificationPermissionStatus.notDetermined,
      afterRequest: NotificationPermissionStatus.granted,
    );
    final db = await pumpScreen(tester, const ReminderScreen(),
        permission: permission);
    await tapText(tester, 'Done');

    expect(find.text('Allow notifications?'), findsOneWidget);
    expect(permission.requests, 0, reason: 'nog niet voor de uitleg');

    await tapText(tester, 'Continue');
    expect(permission.requests, 1);
    final profile = await ProfileRepository(db).get();
    expect(profile.notifyProgramme, isTrue);
    expect(profile.notifyTimeMinutes, 22 * 60);
    expect(find.byType(AppShell), findsOneWidget);
  });

  screenTest('Not now in de uitleg: verder zonder herinnering, geen venster',
      (tester) async {
    final permission =
        FakeNotificationPermission(NotificationPermissionStatus.notDetermined);
    final db = await pumpScreen(tester, const ReminderScreen(),
        permission: permission);
    await tapText(tester, 'Done');
    await tapText(tester, 'Not now');

    expect(permission.requests, 0);
    final profile = await ProfileRepository(db).get();
    expect(profile.intakeCompletedAt, isNotNull);
    expect(profile.notifyProgramme, isFalse);
    expect(find.byType(AppShell), findsOneWidget);
  });

  screenTest('geweigerd: uitleg wat dat betekent en verder zonder herinnering',
      (tester) async {
    final permission = FakeNotificationPermission(
      NotificationPermissionStatus.notDetermined,
      afterRequest: NotificationPermissionStatus.blocked,
    );
    final db = await pumpScreen(tester, const ReminderScreen(),
        permission: permission);
    await tapText(tester, 'Done');
    await tapText(tester, 'Continue');

    expect(find.text('No reminders for now'), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);

    await tapText(tester, 'Continue');
    final profile = await ProfileRepository(db).get();
    expect(profile.intakeCompletedAt, isNotNull);
    expect(profile.notifyProgramme, isFalse);
    expect(find.byType(AppShell), findsOneWidget);
  });

  screenTest('geblokkeerd: geen systeemvenster, wel de weg naar instellingen',
      (tester) async {
    final permission =
        FakeNotificationPermission(NotificationPermissionStatus.blocked);
    await pumpScreen(tester, const ReminderScreen(), permission: permission);
    await tapText(tester, 'Done');

    expect(find.text('Notifications are turned off'), findsOneWidget);
    await tapText(tester, 'Open settings');
    expect(permission.settingsOpened, 1);
    expect(permission.requests, 0);
    expect(find.byType(ReminderScreen), findsOneWidget);

    // Terug uit de instellingen met meldingen aan: meteen verder.
    permission.current = NotificationPermissionStatus.granted;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byType(AppShell), findsOneWidget);
  });

  screenTest('geblokkeerd: verder zonder herinnering kan altijd',
      (tester) async {
    final permission =
        FakeNotificationPermission(NotificationPermissionStatus.blocked);
    final db = await pumpScreen(tester, const ReminderScreen(),
        permission: permission);
    await tapText(tester, 'Done');
    await tapText(tester, 'Continue without reminders');

    expect(permission.requests, 0);
    expect((await ProfileRepository(db).get()).notifyProgramme, isFalse);
    expect(find.byType(AppShell), findsOneWidget);
  });

  group('ReminderService', () {
    test('zet de herinnering uit als meldingen niet meer mogen', () async {
      final db = memoryDb();
      addTearDown(db.close);
      final profiles = ProfileRepository(db);
      await profiles.setNotification(enabled: true, minutes: 21 * 60);

      await ReminderService(profiles,
              FakeNotificationPermission(NotificationPermissionStatus.blocked))
          .reconcileWithPermission();

      final profile = await profiles.get();
      expect(profile.notifyProgramme, isFalse);
      expect(profile.notifyTimeMinutes, 21 * 60, reason: 'tijd blijft bewaard');
    });

    test('laat de herinnering staan als meldingen mogen', () async {
      final db = memoryDb();
      addTearDown(db.close);
      final profiles = ProfileRepository(db);
      await profiles.setNotification(enabled: true, minutes: 21 * 60);

      await ReminderService(profiles,
              FakeNotificationPermission(NotificationPermissionStatus.granted))
          .reconcileWithPermission();

      expect((await profiles.get()).notifyProgramme, isTrue);
    });
  });
}
