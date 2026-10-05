import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/intake/intake_service.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/screens/app_shell.dart';
import 'package:rest4more/screens/onboarding/activities_screen.dart';
import 'package:rest4more/screens/onboarding/obstacle_screen.dart';
import 'package:rest4more/screens/onboarding/plan_screen.dart';
import 'package:rest4more/screens/onboarding/reminder_screen.dart';
import 'package:rest4more/screens/onboarding/rhythm_screen.dart';
import 'package:rest4more/screens/onboarding/welcome_screen.dart';

import 'onboarding_test_support.dart';

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('obstakel: de eerst gekozen optie wordt bewaard', (tester) async {
    final db = await pumpScreen(tester, const ObstacleScreen());
    await tester.tap(find.text('Planning'));
    await tester.pump();
    await tester.tap(find.text('Scrolling'));
    await tester.pump();
    await tapText(tester, 'Continue');

    expect((await ProfileRepository(db).get()).obstacle, Obstacle.planning);
    expect(find.byType(RhythmScreen), findsOneWidget);
  });

  testWidgets('obstakel: een eerder antwoord staat weer geselecteerd',
      (tester) async {
    final db = await pumpScreen(tester, const ObstacleScreen());
    await tester.tap(find.text('Phone as alarm'));
    await tester.pump();
    await tapText(tester, 'Continue');

    await pumpScreen(tester, const ObstacleScreen(), db: db);
    await tester.pumpAndSettle();
    await tapText(tester, 'Continue');
    expect((await ProfileRepository(db).get()).obstacle, Obstacle.alarm);
  });

  testWidgets('ritme: na middernacht wordt bewaard', (tester) async {
    final db = await pumpScreen(tester, const RhythmScreen());
    await tester.tap(find.text('After midnight'));
    await tester.pump();
    await tapText(tester, 'Continue');

    final progress = await IntakeService(ProfileRepository(db)).load();
    expect(progress.rhythm, 2);
    expect(find.byType(ActivitiesScreen), findsOneWidget);
  });

  testWidgets('activiteiten: de eerst gekozen optie wordt bewaard',
      (tester) async {
    final db = await pumpScreen(tester, const ActivitiesScreen());
    await tester.tap(find.text('Paper reading'));
    await tester.pump();
    await tester.tap(find.text('Quiet moments'));
    await tester.pump();
    await tapText(tester, 'Continue');

    expect((await ProfileRepository(db).get()).preferredActivity,
        PreferredActivity.reading);
    expect(find.byType(PlanScreen), findsOneWidget);
  });

  testWidgets('plan: het bekijken van het plan wordt onthouden', (tester) async {
    final db = await pumpScreen(tester, const PlanScreen());
    await tapText(tester, 'Start your plan');
    expect((await ProfileRepository(db).get()).intakeStep, 5);
    expect(find.byType(ReminderScreen), findsOneWidget);
  });

  testWidgets('herinnering aan: Done bewaart de tijd en opent de app',
      (tester) async {
    final db = await pumpScreen(tester, const ReminderScreen());
    await tapText(tester, 'Done');

    final profile = await ProfileRepository(db).get();
    expect(profile.intakeCompletedAt, isNotNull);
    expect(profile.notifyProgramme, isTrue);
    expect(profile.notifyTimeMinutes, 22 * 60);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(ReminderScreen), findsNothing);
  });

  testWidgets('herinnering uit: er wordt niets ingepland', (tester) async {
    final db = await pumpScreen(tester, const ReminderScreen());
    await tapText(tester, 'Maybe later');

    final profile = await ProfileRepository(db).get();
    expect(profile.intakeCompletedAt, isNotNull);
    expect(profile.notifyProgramme, isFalse);
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('de hele onboarding van begin tot eind vult het profiel',
      (tester) async {
    final db = await pumpScreen(tester, const WelcomeScreen());
    await tapText(tester, 'Get started');
    await tapText(tester, 'Use less social media');
    await tapText(tester, 'Continue');
    await tapText(tester, 'Restless thoughts');
    await tapText(tester, 'Continue');
    await tapText(tester, '10:00 PM – 12:00 AM');
    await tapText(tester, 'Continue');
    await tapText(tester, 'Evening breathing routines');
    await tapText(tester, 'Continue');
    await tapText(tester, 'Start your plan');
    await tapText(tester, 'Done');

    final profile = await ProfileRepository(db).get();
    expect(profile.primaryGoal, PrimaryGoal.social);
    expect(profile.obstacle, Obstacle.thoughts);
    expect(profile.bedtimeMinutes, 22 * 60);
    expect(profile.preferredActivity, PreferredActivity.breathing);
    expect(profile.notifyProgramme, isTrue);
    expect(profile.intakeCompletedAt, isNotNull);
    expect(find.byType(AppShell), findsOneWidget);

    final progress = IntakeService.progressOf(profile);
    expect(progress.step, OnboardingStep.done);
  });
}
