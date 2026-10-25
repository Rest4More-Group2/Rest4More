import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/intake/intake_service.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/screens/onboarding/adjust_plan_screen.dart';
import 'package:rest4more/screens/onboarding/plan_screen.dart';

import '../data/test_support.dart';
import 'onboarding_test_support.dart';

void main() {
  screenTest('het planscherm legt uit waarom dit plan is gekozen',
      (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    final intake = IntakeService(ProfileRepository(db));
    await intake.saveGoal(0);
    await intake.saveObstacles([2]);

    await pumpScreen(tester, const PlanScreen(), db: db);
    await settle(tester);

    expect(find.text('Why we chose this for you'), findsOneWidget);
    expect(find.text('Your goal'), findsOneWidget);
    expect(find.text('What gets in the way'), findsOneWidget);
    expect(find.textContaining('not medical advice'), findsOneWidget);
  });

  screenTest('kleiner maken, bekijken en bevestigen', (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    final intake = IntakeService(ProfileRepository(db));
    await intake.saveGoal(1);
    await intake.saveObstacles([3]);
    await intake.saveActivities([2]);

    await pumpScreen(tester, const PlanScreen(), db: db);
    await settle(tester);
    await tester.tap(find.text('Adjust plan settings'));
    await settle(tester);
    expect(find.byType(AdjustPlanScreen), findsOneWidget);

    await tester.tap(find.text('Smaller steps'));
    await settle(tester);
    await tester.tap(find.text('Review changes'));
    await settle(tester);

    // Nog niets bewaard tot de gebruiker bevestigt.
    expect(find.text('Standard steps  →  Smaller steps'), findsOneWidget);
    expect((await ProfileRepository(db).get()).stepSize, isNull);

    await tester.tap(find.text('Confirm changes'));
    await settle(tester);

    expect(find.byType(AdjustPlanScreen), findsNothing);
    expect(find.byType(PlanScreen), findsOneWidget);
    final profile = await ProfileRepository(db).get();
    expect(profile.stepSize, StepSize.short);
    expect(profile.primaryGoal, PrimaryGoal.routine);
    expect(profile.obstacle, Obstacle.planning);
    expect(profile.preferredActivity, PreferredActivity.breathing);
  });

  screenTest('zonder wijziging kan er niets worden bevestigd', (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    await IntakeService(ProfileRepository(db)).saveGoal(0);

    await pumpScreen(tester, const AdjustPlanScreen(), db: db);
    await settle(tester);
    await tester.tap(find.text('Review changes'));
    await settle(tester);
    expect(find.text('Confirm changes'), findsNothing);
  });
}
