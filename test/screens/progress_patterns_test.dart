import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/screens/progress_tab.dart';

import '../data/test_support.dart';
import 'onboarding_test_support.dart';
import 'progress_test_support.dart';

const _patterns = Scaffold(
  body: ProgressTab(initialView: ProgressView.patterns),
);

/// Negen momenten in de laatste vier weken (avondstart 21:00): zes eerder
/// gestopt, waarvan vier na 22:30, één voor 21:00 en één tussen 21:00 en
/// 22:30. Vijf hebben een reden.
Future<void> _seed(AppDatabase db) async {
  await addMoment(db, DateTime(2026, 11, 16, 22, 40), 15,
      early: true, reason: EndReason.couldntSleep);
  await addMoment(db, DateTime(2026, 11, 14, 22, 50), 20,
      early: true, reason: EndReason.couldntSleep);
  await addMoment(db, DateTime(2026, 11, 13, 23, 10), 10,
      early: true, reason: EndReason.neededPhone);
  await addMoment(db, DateTime(2026, 11, 8, 23, 30), 10, early: true);
  await addMoment(db, DateTime(2026, 11, 7, 20), 10,
      early: true, reason: EndReason.notification);
  await addMoment(db, DateTime(2026, 11, 6, 21, 10), 10,
      early: true, reason: EndReason.justWanted);
  await addMoment(db, DateTime(2026, 11, 2, 21), 45);
  await addMoment(db, DateTime(2026, 11, 3, 21), 45);
  await addMoment(db, DateTime(2026, 11, 4, 21), 45);
}

void main() {
  screenTest('te weinig momenten: geen patronen, wel de voortgang erheen',
      (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    await tester.runAsync(() async {
      await addMoment(db, DateTime(2026, 11, 16, 22, 40), 15, early: true);
      await addMoment(db, DateTime(2026, 11, 17, 21), 45);
      // Buiten de laatste 4 weken: telt niet mee.
      await addMoment(db, DateTime(2026, 10, 1, 21), 45);
    });
    await pumpProgress(tester, _patterns, db: db);
    await settle(tester);

    expect(find.text('Patterns appear after 5 moments'), findsOneWidget);
    expect(find.text('2 of 5 moments so far'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      final dot = tester.widget<Container>(find.byKey(ValueKey('low-data-dot-$i')));
      final filled =
          (dot.decoration! as BoxDecoration).color != Colors.transparent;
      expect(filled, i < 2, reason: 'stip $i');
    }
    expect(find.text('When moments end early'), findsNothing);
    expect(find.text('Why they ended early'), findsNothing);
    expect(find.text('Something we noticed'), findsNothing);
    expect(find.textContaining('%'), findsNothing);
  });

  screenTest('zonder enig moment: ook de lege staat', (tester) async {
    await pumpProgress(tester, _patterns);
    await settle(tester);
    expect(find.text('0 of 5 moments so far'), findsOneWidget);
  });

  screenTest('patronen: inzicht, wanneer, waarom en per weekdag',
      (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    await tester.runAsync(() => _seed(db));
    await pumpProgress(tester, _patterns, db: db);
    await settle(tester);

    expect(
      find.text('Last 4 weeks · based on 9 moments, 6 ended early'),
      findsOneWidget,
    );
    expect(find.text('Something we noticed'), findsOneWidget);
    expect(find.text('4 of 6 early stops happened after 10:30 PM.'),
        findsOneWidget);
    expect(find.text('Move reminder to 10:00 PM'), findsOneWidget);

    expect(find.text('Before 9:00 PM'), findsOneWidget);
    expect(find.text('9:00 PM – 10:30 PM'), findsOneWidget);
    expect(find.text('After 10:30 PM'), findsOneWidget);
    expect(
      find.text('Times follow your evening, which starts at 9:00 PM.'),
      findsOneWidget,
    );

    expect(find.text('Couldn’t sleep'), findsOneWidget);
    expect(find.text('Something else'), findsNothing, reason: 'nul keer');
    expect(
      find.text('5 of 6 early stops have a reason. You can skip the question '
          'any time.'),
      findsOneWidget,
    );

    expect(find.text('Moments completed by weekday'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Monday: 1 of 2 completed',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('%'), findsNothing);
  });

  screenTest('Not now verbergt het inzicht', (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    await tester.runAsync(() => _seed(db));
    await pumpProgress(tester, _patterns, db: db);
    await settle(tester);
    await tester.tap(find.text('Not now'));
    await tester.pump();
    expect(find.text('Something we noticed'), findsNothing);
    expect(find.text('When moments end early'), findsOneWidget);
  });

  screenTest('de avondstart aanpassen verschuift de tijden', (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    await tester.runAsync(() => _seed(db));
    await pumpProgress(tester, _patterns, db: db);
    await settle(tester);

    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    // In de tijdkiezer naar invoer met het toetsenbord.
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '10');
    await tester.enterText(find.byType(TextField).last, '00');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(
      find.text('Times follow your evening, which starts at 10:00 PM.'),
      findsOneWidget,
    );
    expect(find.text('After 11:30 PM'), findsOneWidget);
  });

  screenTest('herinnering verzetten via het inzicht', (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    await tester.runAsync(() async {
      await _seed(db);
      final profiles = ProfileRepository(db);
      await profiles.upsert(const ProfileDraft(displayName: 'Test'));
      await profiles.setNotification(enabled: true, minutes: 23 * 60);
    });
    await pumpProgress(tester, _patterns, db: db);
    await settle(tester);

    await tester.tap(find.text('Move reminder to 10:00 PM'));
    await tester.pumpAndSettle();
    // De kiezer staat al op het voorstel.
    await tester.tap(find.text('OK'));
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }

    final profile =
        await tester.runAsync(() => ProfileRepository(db).get());
    expect(profile!.notifyProgramme, isTrue);
    expect(profile.notifyTimeMinutes, 22 * 60);
    expect(find.text('Your daily reminder is now at 10:00 PM.'), findsOneWidget);
    expect(find.text('Something we noticed'), findsNothing);
  });

  screenTest('loopt niet over bij grote letters', (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    await tester.runAsync(() => _seed(db));
    await pumpProgress(
      tester,
      _patterns,
      db: db,
      textScale: 2,
      size: const Size(320, 5000),
    );
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Why they ended early'), findsOneWidget);
  });

  screenTest('lage data bij grote letters loopt niet over', (tester) async {
    await pumpProgress(tester, _patterns, textScale: 2, size: const Size(320, 1600));
    await settle(tester);
    expect(tester.takeException(), isNull);
  });
}
