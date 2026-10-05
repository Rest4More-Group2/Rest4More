import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/intake/intake_service.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/screens/onboarding/plan_screen.dart';

import '../data/test_support.dart';
import 'onboarding_test_support.dart';

void main() {
  screenTest('het planscherm toont de dagen van het echte plan', (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    final intake = IntakeService(ProfileRepository(db));
    await intake.saveGoal(0);
    await intake.saveObstacles([2]);
    await intake.saveActivities([1]);

    await pumpScreen(tester, const PlanScreen(), db: db);
    await settle(tester);

    // Fase 1: dag 1 tot en met 4.
    expect(find.text('Day 1: Your starting point'), findsOneWidget);
    expect(find.text('Day 4: Give the space a purpose'), findsOneWidget);
    expect(find.text('Day 5: Protect a starting moment'), findsNothing);
    expect(find.textContaining('put phone away earlier'), findsOneWidget);
    expect(find.textContaining('restless thoughts'), findsOneWidget);
    // De eigen keuze staat in de tekst van dag 4.
    expect(find.textContaining('reading a few pages'), findsOneWidget);

    // Fase 2 en 3.
    await tester.tap(find.text('Day 5–9'));
    await settle(tester);
    expect(find.text('Day 5: Protect a starting moment'), findsOneWidget);
    expect(find.text('Day 9: Finish one thing'), findsOneWidget);
    expect(find.text('Day 4: Give the space a purpose'), findsNothing);

    await tester.tap(find.text('Day 10–14'));
    await settle(tester);
    expect(find.text('Day 14: Your routine from here'), findsOneWidget);
  });
}
