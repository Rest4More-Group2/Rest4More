import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/intake/intake_service.dart';
import 'package:rest4more/data/programme/content_catalog.dart';
import 'package:rest4more/data/programme/plan_input.dart';
import 'package:rest4more/data/programme/plan_preview.dart';
import 'package:rest4more/data/programme/plan_service.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';

import '../data/test_support.dart';

ContentCatalog loadCatalog() => ContentCatalog.parse(
    File('assets/programme/programme_content.json').readAsStringSync());

void main() {
  final catalog = loadCatalog();

  test('het voorbeeld heeft veertien dagen met titel en actie', () {
    final preview = PlanPreview.build(
        const PlanInput(goal: 'social', obstacle: 'alarm'), catalog);
    expect(preview.days, hasLength(14));
    expect(preview.days.first.title, 'Your starting point');
    expect(preview.days.every((d) => d.action.isNotEmpty), isTrue);
    expect(preview.days.any((d) => d.action.contains('{')), isFalse);
  });

  test('de dagen per fase', () {
    final preview = PlanPreview.build(
        const PlanInput(goal: 'phone', obstacle: 'scrolling'), catalog);
    expect(preview.daysIn(1, 4).map((d) => d.day), [1, 2, 3, 4]);
    expect(preview.daysIn(5, 9).map((d) => d.day), [5, 6, 7, 8, 9]);
    expect(preview.daysIn(10, 14).map((d) => d.day), [10, 11, 12, 13, 14]);
  });

  test('de reden noemt het doel en de belemmering in gewone woorden', () {
    final preview = PlanPreview.build(
        const PlanInput(goal: 'routine', obstacle: 'no_routine'), catalog);
    expect(preview.reason, contains('build a routine'));
    expect(preview.reason, contains('not having a routine yet'));
    expect(preview.reason, isNot(contains('no_routine')));
  });

  test('de acties volgen de gekozen activiteit', () {
    final reading = PlanPreview.build(
        PlanInput(goal: 'phone', obstacle: 'alarm', activity: PlanPhrases.forActivity(PreferredActivity.reading).activity),
        catalog);
    final breathing = PlanPreview.build(
        PlanInput(goal: 'phone', obstacle: 'alarm', activity: PlanPhrases.forActivity(PreferredActivity.breathing).activity),
        catalog);
    expect(reading.days[3].action, contains('reading a few pages'));
    expect(breathing.days[3].action, contains('slow breathing'));
  });

  test('het voorbeeld is precies het plan dat daarna wordt gemaakt', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final intake = IntakeService(ProfileRepository(db));
    await intake.saveGoal(1);
    await intake.saveObstacles([3]);
    await intake.saveActivities([2]);
    final before = PlanInput.fromProfile(await ProfileRepository(db).get())!;
    final preview = PlanPreview.build(before, catalog);

    await intake.complete(reminderEnabled: true, reminderMinutes: 21 * 60);
    await PlanService(db, () async => catalog).ensurePlan();
    final days = await db.select(db.programmeDays).get()
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    for (var i = 0; i < 14; i++) {
      expect(days[i].snapshot['title'], preview.days[i].title);
      expect(days[i].snapshot['action'], preview.days[i].action);
    }
  });
}
