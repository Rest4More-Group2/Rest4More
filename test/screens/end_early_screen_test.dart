import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/screens/end_early_screen.dart';

import 'onboarding_test_support.dart';

void main() {
  /// Opent het scherm vanaf een knop en onthoudt wat het teruggeeft.
  Future<List<bool?>> open(
    WidgetTester tester, {
    DateTime Function()? now,
  }) async {
    final results = <bool?>[];
    await pumpScreen(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => results.add(await Navigator.of(context)
              .push<bool>(MaterialPageRoute<bool>(
            builder: (_) => EndEarlyScreen(now: now),
          ))),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // de overgang
    return results;
  }

  bool enabled(WidgetTester tester, String label) {
    final button = tester.widget<ButtonStyleButton>(find.ancestor(
        of: find.text(label), matching: find.bySubtype<ButtonStyleButton>()));
    return button.enabled;
  }

  Future<void> unlock(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
  }

  screenTest('eerst dicht: pauze, aftellen en uitgeschakelde knoppen',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final results = await open(tester);

    expect(find.text('Take a moment to breathe'), findsOneWidget);
    expect(
        find.text('Is this something you need, or something you reached for?'),
        findsOneWidget);
    expect(find.text('Buttons unlock after 5 seconds.'), findsOneWidget);
    expect(enabled(tester, 'Keep going'), isFalse);
    expect(enabled(tester, 'End session'), isFalse);

    // Het aftellen loopt mee met de balk.
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('You can choose in 4 s'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'You can choose in 4 seconds\. '
          r'Buttons are disabled')),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.text('Keep going')),
      isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
    );

    // Net voor de 5 seconden (0,4 + 1,2 + 2,9) nog steeds dicht.
    await tester.pump(const Duration(milliseconds: 2900));
    expect(find.text('You can choose in 1 s'), findsOneWidget);
    await tester.tap(find.text('End session'), warnIfMissed: false);
    await tester.tap(find.text('Keep going'), warnIfMissed: false);
    await tester.pump();
    expect(results, isEmpty);
    expect(find.byType(EndEarlyScreen), findsOneWidget);
    semantics.dispose();
  });

  screenTest('na 5 seconden open: andere tekst en beide knoppen werken',
      (tester) async {
    await open(tester);
    await unlock(tester);

    expect(find.text('Ready when you are'), findsOneWidget);
    expect(
        find.text('Would you like to end this session early, or keep going?'),
        findsOneWidget);
    expect(find.text('You can choose now.'), findsOneWidget);
    expect(find.text('Ending early is logged as a stopped session.'),
        findsOneWidget);
    expect(enabled(tester, 'Keep going'), isTrue);
    expect(enabled(tester, 'End session'), isTrue);
  });

  screenTest('Keep going geeft false, End session geeft true', (tester) async {
    var results = await open(tester);
    await unlock(tester);
    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();
    expect(results, [false]);
    expect(find.byType(EndEarlyScreen), findsNothing);

    results = await open(tester);
    await unlock(tester);
    await tester.tap(find.text('End session'));
    await tester.pumpAndSettle();
    expect(results, [true]);
  });

  screenTest('het kruisje en de terugknop sluiten zonder te stoppen',
      (tester) async {
    var results = await open(tester);
    await tester.tap(find.byTooltip('Close and keep going'));
    await tester.pumpAndSettle();
    expect(results, [null]);

    results = await open(tester);
    await tester.binding.handlePopRoute(); // Android-terugknop
    await tester.pumpAndSettle();
    expect(results, [null]);
  });

  screenTest('terug uit de achtergrond na meer dan 5 s: meteen open',
      (tester) async {
    var now = DateTime(2026, 11, 4, 10, 46);
    await open(tester, now: () => now);
    await tester.pump(const Duration(seconds: 1));

    // Op de achtergrond lopen er geen frames, dus de balk staat stil.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = now.add(const Duration(seconds: 30));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();

    expect(find.text('Ready when you are'), findsOneWidget);
    expect(enabled(tester, 'End session'), isTrue);
  });
}
