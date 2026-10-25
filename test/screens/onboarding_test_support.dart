import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/notifications/notification_permission.dart';
import 'package:rest4more/providers/database_providers.dart';
import 'package:rest4more/providers/notification_providers.dart';

import '../data/test_support.dart';

/// Toestemming voor meldingen zonder systeem. Onthoudt wat er gevraagd is.
class FakeNotificationPermission extends NotificationPermission {
  FakeNotificationPermission(this.current,
      {NotificationPermissionStatus? afterRequest, this.canOpenSettings = true})
      : afterRequest = afterRequest ?? current;

  NotificationPermissionStatus current;
  final NotificationPermissionStatus afterRequest;
  final bool canOpenSettings;
  int requests = 0;
  int settingsOpened = 0;

  @override
  Future<NotificationPermissionStatus> status() async => current;

  @override
  Future<NotificationPermissionStatus> request() async {
    requests++;
    return current = afterRequest;
  }

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return canOpenSettings;
  }
}

/// Een hoog telefoonscherm en een database in het geheugen, zoals de andere
/// schermtests. Zonder [permission] zijn meldingen al toegestaan.
Future<AppDatabase> pumpScreen(WidgetTester tester, Widget screen,
    {AppDatabase? db, NotificationPermission? permission}) async {
  // De schermen hebben vaste hoogtes. In de testfont (Ahem) lopen sommige
  // kaarten over, dat zegt niets over wat er wordt opgeslagen. Layoutfouten
  // negeren we hier, alle andere fouten blijven de test laten falen.
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    originalOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = originalOnError);

  tester.view.physicalSize = const Size(1170, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final database = db ?? memoryDb();
  if (db == null) addTearDown(database.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        notificationPermissionProvider.overrideWithValue(permission ??
            FakeNotificationPermission(NotificationPermissionStatus.granted)),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pump();
  return database;
}

/// Zoals `testWidgets`, maar haalt na afloop de schermen weg en laat de
/// database-stromen netjes sluiten. Anders blijft er een timer van de database
/// hangen en faalt de test, ook al klopt alles.
void screenTest(String description, Future<void> Function(WidgetTester) body) {
  testWidgets(description, (tester) async {
    await body(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });
}

/// Wacht tot de app klaar is, ook als er echte I/O bij zit (zoals het laden van
/// de inhoud van het programma). `pumpAndSettle` alleen laat daar de klok
/// doorlopen zonder dat de I/O ooit klaar komt.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 100; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 100));
    // Klaar zodra het laadscherm weg is, plus nog een paar beelden voor de rest.
    if (i > 15 && find.byType(CircularProgressIndicator).evaluate().isEmpty) {
      break;
    }
  }
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}
