import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/screens/onboarding/goal_screen.dart';
import 'package:rest4more/screens/onboarding/obstacle_screen.dart';

import 'onboarding_test_support.dart';

void main() {
  screenTest('Continue bewaart de gekozen doelstelling en gaat verder',
      (tester) async {
    final db = await pumpScreen(tester, const GoalScreen());

    await tester.tap(find.text('Build a routine'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final profile = await ProfileRepository(db).get();
    expect(profile.primaryGoal, PrimaryGoal.routine);
    expect(profile.intakeStep, 1);
    expect(find.byType(ObstacleScreen), findsOneWidget);
  });

  screenTest('zonder te kiezen wordt het voorgeselecteerde doel bewaard',
      (tester) async {
    final db = await pumpScreen(tester, const GoalScreen());
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect((await ProfileRepository(db).get()).primaryGoal, PrimaryGoal.phone);
  });

  screenTest('een eerder antwoord wordt weer getoond', (tester) async {
    final first = await pumpScreen(tester, const GoalScreen());
    await tester.tap(find.text('Use less social media'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Het scherm opnieuw openen met dezelfde database.
    await pumpScreen(tester, const GoalScreen(), db: first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(
        (await ProfileRepository(first).get()).primaryGoal, PrimaryGoal.social);
  });
}
