import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/intake/intake_service.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/providers/intake_providers.dart';
import 'package:rest4more/screens/app_root.dart';
import 'package:rest4more/screens/app_shell.dart';
import 'package:rest4more/screens/onboarding/activities_screen.dart';
import 'package:rest4more/screens/onboarding/goal_screen.dart';
import 'package:rest4more/screens/onboarding/obstacle_screen.dart';
import 'package:rest4more/screens/onboarding/reminder_screen.dart';
import 'package:rest4more/screens/onboarding/welcome_screen.dart';

import '../data/test_support.dart';
import 'onboarding_test_support.dart';

class _FakeIntake extends IntakeService {
  _FakeIntake(this._load) : super(ProfileRepository(memoryDb()));

  final Future<IntakeProgress> Function() _load;

  @override
  Future<IntakeProgress> load() => _load();
}

Future<void> _pumpWith(WidgetTester tester, IntakeService intake) async {
  tester.view.physicalSize = const Size(1170, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [intakeServiceProvider.overrideWithValue(intake)],
      child: const MaterialApp(home: AppRoot()),
    ),
  );
  await tester.pump();
}

void main() {
  Future<AppDatabase> startAt(
    WidgetTester tester,
    Future<void> Function(IntakeService intake) prepare,
  ) async {
    final db = memoryDb();
    addTearDown(db.close);
    await prepare(IntakeService(ProfileRepository(db)));
    await pumpScreen(tester, const AppRoot(), db: db);
    await tester.pumpAndSettle();
    return db;
  }

  testWidgets('een nieuwe gebruiker begint bij de welkomstpagina',
      (tester) async {
    await startAt(tester, (_) async {});
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
  });

  testWidgets('tijdens het laden is er een rustig laadscherm', (tester) async {
    final gate = Completer<IntakeProgress>();
    await _pumpWith(tester, _FakeIntake(() => gate.future));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);

    gate.complete(const IntakeProgress(step: OnboardingStep.welcome));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('een onderbroken onboarding gaat verder bij de volgende stap',
      (tester) async {
    await startAt(tester, (intake) => intake.saveGoal(1));
    expect(find.byType(ObstacleScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
  });

  testWidgets('Terug gaat naar de vorige stappen, tot en met het begin',
      (tester) async {
    await startAt(tester, (intake) async {
      await intake.saveGoal(0);
      await intake.saveObstacles([0]);
    });
    // Stap 3: ritme. Terug is obstakel, dan doel, dan welkom.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    expect(navigator.canPop(), isTrue);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.byType(ObstacleScreen), findsOneWidget);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.byType(GoalScreen), findsOneWidget);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(navigator.canPop(), isFalse);
  });

  testWidgets('elke opgeslagen stap opent het juiste scherm', (tester) async {
    await startAt(tester, (intake) async {
      await intake.saveGoal(0);
      await intake.saveObstacles([0]);
      await intake.saveRhythm(0);
    });
    expect(find.byType(ActivitiesScreen), findsOneWidget);
  });

  testWidgets('plan bekeken: verder bij de herinnering', (tester) async {
    await startAt(tester, (intake) => intake.savePlanSeen());
    expect(find.byType(ReminderScreen), findsOneWidget);
  });

  testWidgets('afgeronde onboarding gaat meteen naar de app', (tester) async {
    await startAt(
      tester,
      (intake) => intake.complete(reminderEnabled: true, reminderMinutes: 1320),
    );
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(GoalScreen), findsNothing);
  });

  testWidgets('een afgeronde onboarding blijft de app tonen, geen Terug naar de intake',
      (tester) async {
    await startAt(
      tester,
      (intake) => intake.complete(reminderEnabled: false),
    );
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    expect(navigator.canPop(), isFalse);
  });

  testWidgets('een fout bij het lezen toont een melding met opnieuw proberen',
      (tester) async {
    var attempts = 0;
    await _pumpWith(tester, _FakeIntake(() async {
      attempts++;
      if (attempts == 1) throw StateError('database stuk');
      return const IntakeProgress(step: OnboardingStep.welcome);
    }));
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('de onboarding voltooien en opnieuw opstarten opent de app',
      (tester) async {
    final db = await startAt(tester, (_) async {});
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start your plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(AppShell), findsOneWidget);

    // "App opnieuw starten": een nieuwe root op dezelfde database.
    await pumpScreen(tester, const AppRoot(), db: db);
    await tester.pumpAndSettle();
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
  });
}
