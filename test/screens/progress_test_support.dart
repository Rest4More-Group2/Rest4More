import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/notifications/notification_permission.dart';
import 'package:rest4more/data/repositories/focus_session_repository.dart';
import 'package:rest4more/data/repositories/session_end_reason_repository.dart';
import 'package:rest4more/l10n/app_localizations.dart';
import 'package:rest4more/providers/database_providers.dart';
import 'package:rest4more/providers/notification_providers.dart';
import 'package:rest4more/providers/progress_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/test_support.dart';
import 'onboarding_test_support.dart';

/// Woensdag 18 november 2026, 12:00.
final progressNow = DateTime(2026, 11, 18, 12);

/// Zoals `pumpScreen`, maar met een vaste klok voor Progress en zonder het
/// negeren van overloopfouten: tekst mag bij grote letters niet buiten beeld
/// lopen. [textScale] vergroot alle tekst.
Future<AppDatabase> pumpProgress(
  WidgetTester tester,
  Widget screen, {
  AppDatabase? db,
  double textScale = 1,
  Size size = const Size(390, 1600),
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final database = db ?? memoryDb();
  if (db == null) addTearDown(database.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        progressClockProvider.overrideWithValue(() => progressNow),
        notificationPermissionProvider.overrideWithValue(
          FakeNotificationPermission(NotificationPermissionStatus.granted),
        ),
        reminderSchedulerProvider.overrideWithValue(FakeReminderScheduler()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  await tester.pump();
  return database;
}

/// Legt een afgerond of eerder gestopt moment vast, met blokkade.
Future<String> addMoment(
  AppDatabase db,
  DateTime start,
  int minutes, {
  bool early = false,
  bool blocking = true,
  EndReason? reason,
}) async {
  final end = start.add(Duration(minutes: minutes));
  final s = await FocusSessionRepository(db).recordFinished(
    mode: 'evening',
    source: SessionSource.manual,
    platform: SessionPlatform.android,
    startedAt: start,
    endedAt: end,
    outcome: early ? SessionOutcome.stoppedEarly : SessionOutcome.completed,
    blockingConfirmedAt: blocking ? start : null,
    blockingReleasedAt: blocking ? end : null,
  );
  if (reason != null) await SessionEndReasonRepository(db).set(s.id, reason);
  return s.id;
}
