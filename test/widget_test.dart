import 'package:flutter/painting.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/main.dart';
import 'package:rest4more/providers/database_providers.dart';

import 'data/test_support.dart';

void main() {
  testWidgets('app start zonder fouten met een database in het geheugen',
      (tester) async {
    // Een hoog telefoonscherm: de welkomstpagina past niet in een kolom zonder scrollen op een kleiner scherm.
    tester.view.physicalSize = const Size(1170, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = memoryDb();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MyApp(),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(MyApp), findsOneWidget);
  });
}
