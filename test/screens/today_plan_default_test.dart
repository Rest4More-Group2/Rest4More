import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/screens/app_shell.dart';

import '../data/test_support.dart';
import 'onboarding_test_support.dart';

void main() {
  screenTest('zonder plan toont Today zijn standaardtekst', (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    // Onboarding niet af: AppShell direct tonen.
    await pumpScreen(tester, const AppShell(), db: db);
    await tester.pumpAndSettle();
    expect(find.text('Make a little room for rest'), findsOneWidget);
  });
}
