import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/data/intake/intake_service.dart';
import 'package:rest4more/providers/intake_providers.dart';
import 'package:rest4more/providers/plan_providers.dart';

import 'app_shell.dart';
import 'onboarding/activities_screen.dart';
import 'onboarding/goal_screen.dart';
import 'onboarding/obstacle_screen.dart';
import 'onboarding/plan_screen.dart';
import 'onboarding/reminder_screen.dart';
import 'onboarding/rhythm_screen.dart';
import 'onboarding/welcome_screen.dart';

/// Eerste scherm van de app. Kijkt in de database waar de gebruiker is:
/// onboarding niet gedaan of niet af, dan verder waar het was gebleven; klaar,
/// dan naar de app.
class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});

  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> {
  static const Color background = Color(0xFFFCFAF7);
  static const Color brown = Color(0xFF8B6043);

  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    setState(() => _failed = false);
    final IntakeProgress progress;
    try {
      progress = await ref.read(intakeServiceProvider).load();
    } on Object {
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) return;

    final navigator = Navigator.of(context);
    if (progress.completed) {
      // Mislukte of nog niet gemaakte plannen komen hier alsnog tot stand.
      try {
        await ref.read(planServiceProvider).ensurePlan();
      } on Object {
        // De app werkt ook zonder plan, met de standaardtekst.
      }
      if (!mounted) return;
      navigator.pushReplacement(_instant(const AppShell()));
      return;
    }
    // De schermen tot en met het huidige, zodat Terug naar de vorige stap gaat.
    final stack = onboardingScreens(progress.step);
    navigator.pushReplacement(_instant(stack.first));
    for (final screen in stack.skip(1)) {
      navigator.push(_instant(screen));
    }
  }

  /// Zonder animatie: de gebruiker ziet meteen waar hij was.
  PageRoute<void> _instant(Widget screen) => PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondary) => screen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Center(
        child: _failed
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Something went wrong while opening the app.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _route,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(color: brown),
      ),
    );
  }
}

/// De onboardingschermen in volgorde, tot en met [step]. Alleen [AppRoot] en
/// de tests gebruiken dit.
List<Widget> onboardingScreens(OnboardingStep step) {
  const all = <Widget>[
    WelcomeScreen(),
    GoalScreen(),
    ObstacleScreen(),
    RhythmScreen(),
    ActivitiesScreen(),
    PlanScreen(),
    ReminderScreen(),
  ];
  final last = switch (step) {
    OnboardingStep.welcome => 0,
    OnboardingStep.goal => 1,
    OnboardingStep.obstacle => 2,
    OnboardingStep.rhythm => 3,
    OnboardingStep.activities => 4,
    OnboardingStep.plan => 5,
    OnboardingStep.reminder => 6,
    OnboardingStep.done => 6,
  };
  return all.sublist(0, last + 1);
}
