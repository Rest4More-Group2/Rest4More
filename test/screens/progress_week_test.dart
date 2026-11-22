import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/screens/progress_tab.dart';

import '../data/test_support.dart';
import 'onboarding_test_support.dart';
import 'progress_test_support.dart';

Future<void> _seedWeek(dynamic db) async {
  // Vorige week: 1 afgerond, 2 eerder gestopt.
  await addMoment(db, DateTime(2026, 11, 9, 21), 45);
  await addMoment(db, DateTime(2026, 11, 10, 22, 40), 15, early: true);
  await addMoment(db, DateTime(2026, 11, 11, 22, 40), 15, early: true);
  // Deze week (vanaf maandag 16 nov): 2 afgerond, 1 eerder gestopt, 1 zonder
  // blokkade.
  await addMoment(db, DateTime(2026, 11, 16, 21), 45);
  await addMoment(db, DateTime(2026, 11, 17, 21), 50);
  await addMoment(db, DateTime(2026, 11, 17, 22, 40), 15, early: true);
  await addMoment(db, DateTime(2026, 11, 18, 7), 10, blocking: false);
}

void main() {
  screenTest('weekoverzicht met winst, staven en vergelijking', (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    await tester.runAsync(() => _seedWeek(db));
    await pumpProgress(tester, const Scaffold(body: ProgressTab()), db: db);
    await settle(tester);

    expect(find.text('16 – November 22'), findsOneWidget);
    expect(
      find.text('3 moments completed — 2 more than last week.'),
      findsOneWidget,
    );
    expect(find.text('3 of 4'), findsOneWidget);
    expect(find.text('moments completed'), findsOneWidget);
    // 45 + 50 + 15: beschermde tijd en telefoon-weg deze week.
    expect(find.text('1 h 50 min'), findsNWidgets(2));
    expect(find.text('protected time'), findsOneWidget);
    expect(find.text('session time without blocking'), findsOneWidget);
    expect(find.text('ended early'), findsWidgets);
    // Staafwaarden: ma 45, di 65, wo 10.
    expect(find.text('45'), findsOneWidget);
    expect(find.text('65'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label ==
                'Tuesday: 50 min completed, 15 min ended early',
      ),
      findsOneWidget,
    );

    expect(find.text('Compared to last week'), findsOneWidget);
    expect(find.text('3 this week · 1 last week'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(find.text('−1'), findsOneWidget);
    // Phone-away: deze week eerst, dan totaal, met de bron.
    expect(find.text('apps blocked this week'), findsOneWidget);
    expect(find.text('Source: blocking was active during your moments.'),
        findsOneWidget);

    await tester.tap(find.text('Last 4 weeks'));
    await tester.pump();
    expect(find.text('Compared to the 4 weeks before'), findsOneWidget);
    expect(find.text('4 in these 4 weeks · 0 in the 4 before'), findsOneWidget);
  });

  screenTest('terug naar een eerdere week, en de volgende week is dicht in de '
      'huidige week', (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    await tester.runAsync(() => _seedWeek(db));
    await pumpProgress(tester, const Scaffold(body: ProgressTab()), db: db);
    await settle(tester);

    IconButton button(String tooltip) => tester.widget<IconButton>(
      find.widgetWithIcon(
        IconButton,
        tooltip == 'Next week' ? Icons.chevron_right : Icons.chevron_left,
      ),
    );
    expect(button('Next week').onPressed, isNull);

    await tester.tap(find.byTooltip('Previous week'));
    await tester.pump();
    expect(find.text('9 – November 15'), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.text('apps blocked that week'), findsOneWidget);
    // Eerste week met data: verder terug kan niet.
    expect(button('Previous week').onPressed, isNull);
    expect(button('Next week').onPressed, isNotNull);
  });

  screenTest('een week zonder momenten', (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    await tester.runAsync(
      () => addMoment(db, DateTime(2026, 11, 3, 21), 30),
    );
    await pumpProgress(tester, const Scaffold(body: ProgressTab()), db: db);
    await settle(tester);
    expect(find.text('No moments this week.'), findsOneWidget);
    expect(find.text('Minutes per day'), findsNothing);
    expect(find.text('Compared to last week'), findsOneWidget);
  });

  screenTest('See patterns wisselt naar Patterns', (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    await tester.runAsync(() => _seedWeek(db));
    await pumpProgress(tester, const Scaffold(body: ProgressTab()), db: db);
    await settle(tester);
    await tester.tap(find.text('See patterns'));
    await tester.pump();
    expect(find.text('Your week'), findsNothing);
  });

  for (final scale in [1.0, 2.0]) {
    screenTest('loopt niet over bij tekstgrootte $scale', (tester) async {
      final db = memoryDb();
      addTearDown(db.close);
      await tester.runAsync(() => _seedWeek(db));
      await pumpProgress(
        tester,
        const Scaffold(body: ProgressTab()),
        db: db,
        textScale: scale,
        size: const Size(320, 4000),
      );
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Your week'), findsOneWidget);
    });
  }
}
