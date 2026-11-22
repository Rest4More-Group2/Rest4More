import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/screens/end_reason_sheet.dart';

import 'onboarding_test_support.dart';
import 'progress_test_support.dart';

void main() {
  /// Opent de sheet vanaf een knop en onthoudt wat hij teruggeeft.
  Future<List<EndReasonChoice>> open(
    WidgetTester tester, {
    bool afterEnd = false,
    double textScale = 1,
  }) async {
    final results = <EndReasonChoice>[];
    await pumpProgress(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                results.add(await showEndReasonSheet(context, afterEnd: afterEnd)),
            child: const Text('open'),
          ),
        ),
      ),
      textScale: textScale,
      size: const Size(360, 800),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  screenTest('stoppen zonder reden werkt', (tester) async {
    final results = await open(tester);
    expect(find.text('End this moment early?'), findsOneWidget);
    expect(find.text('Your answer stays on this phone.'), findsOneWidget);
    for (final label in [
      'Couldn’t sleep',
      'Needed my phone',
      'A notification',
      'Just wanted to',
      'Something else',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('End moment'));
    await tester.pumpAndSettle();
    expect(results.single, (end: true, reason: null));
  });

  screenTest('een reden kiezen, wisselen en weer leegmaken', (tester) async {
    final results = await open(tester);
    await tester.tap(find.text('A notification'));
    await tester.pump();
    await tester.tap(find.text('Couldn’t sleep'));
    await tester.pump();
    ChoiceChip chip(String label) => tester.widget<ChoiceChip>(
      find.ancestor(of: find.text(label), matching: find.byType(ChoiceChip)),
    );
    expect(chip('Couldn’t sleep').selected, isTrue);
    expect(chip('A notification').selected, isFalse);

    // Nog een keer tikken maakt de keuze leeg.
    await tester.tap(find.text('Couldn’t sleep'));
    await tester.pump();
    expect(chip('Couldn’t sleep').selected, isFalse);

    await tester.tap(find.text('Needed my phone'));
    await tester.pump();
    await tester.tap(find.text('End moment'));
    await tester.pumpAndSettle();
    expect(results.single, (end: true, reason: EndReason.neededPhone));
  });

  screenTest('Keep going en wegvegen laten het moment lopen', (tester) async {
    final results = await open(tester);
    await tester.tap(find.text('Couldn’t sleep'));
    await tester.pump();
    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();
    expect(results.single, (end: false, reason: null));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10)); // buiten de sheet
    await tester.pumpAndSettle();
    expect(results.last, (end: false, reason: null));
  });

  screenTest('na de kaart: bewaren of overslaan, geen Keep going',
      (tester) async {
    final results = await open(tester, afterEnd: true);
    expect(find.text('Your evening ended early'), findsOneWidget);
    expect(find.text('Keep going'), findsNothing);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(results.single, (end: true, reason: null));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Just wanted to'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(results.last, (end: true, reason: EndReason.justWanted));
  });

  screenTest('loopt niet over bij grote letters', (tester) async {
    await open(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Keep going'), 100,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('Keep going'), findsOneWidget);
  });
}
