import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/screens/onboarding/plan_screen.dart';

import '../data/test_support.dart';
import 'onboarding_test_support.dart';

void main() {
  screenTest('zonder doel blijft de vaste tekst van het ontwerp', (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    await pumpScreen(tester, const PlanScreen(), db: db);
    await settle(tester);
    expect(find.text('Create some space'), findsOneWidget);
    expect(find.text('Take one quiet moment'), findsOneWidget);
    expect(find.textContaining('Chosen for your goal'), findsNothing);
  });
}
