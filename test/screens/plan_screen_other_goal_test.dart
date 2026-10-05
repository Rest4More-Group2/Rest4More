import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/intake/intake_service.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/screens/onboarding/plan_screen.dart';

import '../data/test_support.dart';
import 'onboarding_test_support.dart';

void main() {
  screenTest('een ander doel geeft andere tekst in dezelfde dagen',
      (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    final intake = IntakeService(ProfileRepository(db));
    await intake.saveGoal(2);
    await intake.saveObstacles([0]);

    await pumpScreen(tester, const PlanScreen(), db: db);
    await settle(tester);
    expect(find.textContaining('use less social media'), findsOneWidget);
    expect(find.text('Day 1: Your starting point'), findsOneWidget);
  });
}
