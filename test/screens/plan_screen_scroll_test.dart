import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/intake/intake_service.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/screens/onboarding/plan_screen.dart';

import '../data/test_support.dart';
import 'onboarding_test_support.dart';

void main() {
  screenTest('een lang plan kan scrollen zonder fouten', (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    final intake = IntakeService(ProfileRepository(db));
    await intake.saveGoal(1);
    await intake.saveObstacles([5]);
    await pumpScreen(tester, const PlanScreen(), db: db);
    await settle(tester);
    await tester.tap(find.text('Day 5–9'));
    await settle(tester);
    expect(find.byType(SingleChildScrollView), findsWidgets);
  });
}
