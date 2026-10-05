import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/screens/app_shell.dart';
import 'package:rest4more/screens/onboarding/welcome_screen.dart';

import 'onboarding_test_support.dart';

void main() {
  screenTest('de onboarding voltooien maakt een plan en toont dag 1 op Today',
      (tester) async {
    final db = await pumpScreen(tester, const WelcomeScreen());
    Future<void> tap(String text) async {
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
    }

    await tap('Get started');
    await tap('Build a routine');
    await tap('Continue');
    await tap('Scrolling');
    await tap('Continue');
    await tap('10:00 PM – 12:00 AM');
    await tap('Continue');
    await tap('Paper reading');
    await tap('Continue');
    await tap('Start your plan');
    await tap('Done');

    expect(find.byType(AppShell), findsOneWidget);
    expect(await db.select(db.programmeEnrollments).get(), hasLength(1));
    expect(await db.select(db.programmeDays).get(), hasLength(14));

    // De eerste dag van het plan voor het doel "build a routine".
    expect(find.text('DAY 1 OF 14'), findsOneWidget);
    expect(find.text('Your starting point'), findsOneWidget);
  });
}
