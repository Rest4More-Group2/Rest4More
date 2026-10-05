import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/providers/database_providers.dart';

import '../data/test_support.dart';

/// Een hoog telefoonscherm en een database in het geheugen, zoals de andere
/// schermtests.
Future<AppDatabase> pumpScreen(WidgetTester tester, Widget screen,
    {AppDatabase? db}) async {
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
      overrides: [databaseProvider.overrideWithValue(database)],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pump();
  return database;
}
