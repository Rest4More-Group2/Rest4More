import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/repositories/programme_repository.dart';
import 'package:rest4more/screens/progress_tab.dart';

import '../data/test_support.dart';
import 'onboarding_test_support.dart';

Finder _labelled(String label) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.label == label,
    );

void main() {
  screenTest('zonder data: lege staten, geen nullen als voortgang',
      (tester) async {
    await pumpScreen(tester, const Scaffold(body: ProgressTab()));
    await settle(tester);
    expect(find.textContaining('No completed moments yet'), findsOneWidget);
    expect(find.text('No plan started yet.'), findsOneWidget);
    expect(find.text('No blocked time yet.'), findsOneWidget);
  });

  screenTest('toont afgeronde stappen', (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    await tester.runAsync(() async {
      final repo = ProgrammeRepository(db);
      final id = await enrollWithDays(repo);
      final days = await repo.days(id);
      await repo.markCompleted(days.first.id);
    });
    await pumpScreen(tester, const Scaffold(body: ProgressTab()), db: db);
    await settle(tester);
    expect(find.text('1 of 14'), findsOneWidget);
  });

  screenTest('toont de stapstatus per dag', (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    await tester.runAsync(() async {
      final repo = ProgrammeRepository(db);
      final id = await enrollWithDays(repo);
      final days = await repo.days(id);
      await repo.markCompleted(days[0].id);
      await repo.skip(days[1].id);
      await repo.setSize(days[1].id, DaySize.smaller);
      await repo.setSize(days[2].id, DaySize.smaller);
      await repo.setSize(days[0].id, DaySize.smaller);
    });
    await pumpScreen(tester, const Scaffold(body: ProgressTab()), db: db);
    await settle(tester);
    expect(_labelled('Day 1: done, swapped'), findsOneWidget);
    expect(_labelled('Day 2: skipped'), findsOneWidget);
    expect(_labelled('Day 3: open'), findsOneWidget);
  });
}
