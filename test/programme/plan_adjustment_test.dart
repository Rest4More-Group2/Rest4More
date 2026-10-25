import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/intake/intake_service.dart';
import 'package:rest4more/data/programme/content_catalog.dart';
import 'package:rest4more/data/programme/plan_adjustment.dart';
import 'package:rest4more/data/programme/plan_service.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/data/repositories/programme_repository.dart';

import '../data/test_support.dart';

Future<ContentCatalog> loadFromFile() async => ContentCatalog.parse(
    File('assets/programme/programme_content.json').readAsStringSync());

void main() {
  late AppDatabase db;
  late TestClock clock;
  late IntakeService intake;
  late ProfileRepository profiles;
  late PlanAdjustmentService adjust;

  setUp(() {
    db = memoryDb();
    clock = TestClock(DateTime(2026, 3, 2, 18));
    profiles = ProfileRepository(db, now: clock.call);
    intake = IntakeService(profiles);
    adjust = PlanAdjustmentService(db, loadFromFile, now: clock.call);
  });
  tearDown(() => db.close());

  /// Doel phone, belemmering scrolling, ritme 22:00, activiteit reading.
  Future<void> answerUpToPlan() async {
    await intake.saveGoal(0);
    await intake.saveObstacles([0]);
    await intake.saveRhythm(1);
    await intake.saveActivities([1]);
    await intake.savePlanSeen();
  }

  Future<void> finishOnboarding() async {
    await answerUpToPlan();
    await intake.complete(reminderEnabled: false);
    await PlanService(db, loadFromFile, now: clock.call).ensurePlan();
  }

  Future<List<ProgrammeEnrollment>> enrollments() =>
      db.select(db.programmeEnrollments).get();

  Future<List<ProgrammeDay>> daysOf(String enrollmentId) async =>
      (await db.select(db.programmeDays).get())
          .where((d) => d.enrollmentId == enrollmentId)
          .toList()
        ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

  group('PlanAdjustment', () {
    test('alleen wat echt anders is telt als wijziging', () async {
      await answerUpToPlan();
      final profile = await profiles.get();
      final same = PlanAdjustment.between(profile,
          goal: PrimaryGoal.phone,
          obstacle: Obstacle.scrolling,
          activity: PreferredActivity.reading,
          smaller: false);
      expect(same.isEmpty, isTrue);

      final change = PlanAdjustment.between(profile,
          goal: PrimaryGoal.phone,
          obstacle: Obstacle.alarm,
          activity: PreferredActivity.reading,
          smaller: true);
      expect(change.goal, isNull);
      expect(change.activity, isNull);
      expect(change.obstacle, Obstacle.alarm);
      expect(change.stepSize, StepSize.short);
      expect(change.onlyStepSize, isFalse);
    });

    test('het overzicht toont voor en na in gewone woorden', () async {
      await answerUpToPlan();
      final profile = await profiles.get();
      final changes = const PlanAdjustment(
        obstacle: Obstacle.thoughts,
        stepSize: StepSize.short,
      ).changesFrom(profile);
      expect(changes.map((c) => c.label), ['What gets in the way', 'Step size']);
      expect(changes.first.before, 'Scrolling');
      expect(changes.first.after, 'Restless thoughts');
      expect(changes.last.before, 'Standard steps');
      expect(changes.last.after, 'Smaller steps');
    });
  });

  group('bevestigen tijdens de onboarding', () {
    test('andere antwoorden en de stap in de onboarding blijven staan',
        () async {
      await answerUpToPlan();
      final before = await profiles.get();

      await adjust.confirm(const PlanAdjustment(goal: PrimaryGoal.social));

      final after = await profiles.get();
      expect(after.primaryGoal, PrimaryGoal.social);
      expect(after.obstacle, before.obstacle);
      expect(after.preferredActivity, before.preferredActivity);
      expect(after.bedtimeMinutes, before.bedtimeMinutes);
      expect(after.intakeStep, before.intakeStep);
      expect(after.intakeCompletedAt, isNull);
      expect(await enrollments(), isEmpty, reason: 'plan komt aan het eind');
    });

    test('het aangepaste plan wordt het plan na de onboarding', () async {
      await answerUpToPlan();
      await adjust.confirm(const PlanAdjustment(stepSize: StepSize.short));
      await intake.complete(reminderEnabled: false);
      await PlanService(db, loadFromFile, now: clock.call).ensurePlan();

      final enrollment = (await enrollments()).single;
      final days = await daysOf(enrollment.id);
      expect(days, hasLength(14));
      expect(days.every((d) => d.size == DaySize.smaller), isTrue);
    });

    test('niets veranderd: niets geschreven', () async {
      await answerUpToPlan();
      final before = await profiles.get();
      clock.advance(const Duration(minutes: 1));
      await adjust.confirm(const PlanAdjustment());
      expect((await profiles.get()).updatedAt, before.updatedAt);
    });
  });

  group('bevestigen met een lopend programma', () {
    test('een ander doel wordt meteen het actieve programma', () async {
      await finishOnboarding();
      final old = (await enrollments()).single;

      clock.advance(const Duration(minutes: 5));
      await adjust.confirm(const PlanAdjustment(goal: PrimaryGoal.routine));

      final all = await enrollments();
      expect(all, hasLength(2));
      final stopped = all.firstWhere((e) => e.id == old.id);
      final active = all.firstWhere((e) => e.id != old.id);
      expect(stopped.status, EnrollmentStatus.stopped);
      expect(active.status, EnrollmentStatus.active);
      expect(active.selection['goal'], 'routine');

      final days = await daysOf(active.id);
      expect(days, hasLength(14));
      expect(days.first.contentId, 'rfm-en-v1-d01-routine');
    });

    test('alleen een kleinere stap houdt de voortgang', () async {
      await finishOnboarding();
      final enrollment = (await enrollments()).single;
      final programme = ProgrammeRepository(db, now: clock.call);
      final first = (await daysOf(enrollment.id)).first;
      await programme.markCompleted(first.id);

      await adjust.confirm(const PlanAdjustment(stepSize: StepSize.short));

      expect((await enrollments()).single.id, enrollment.id);
      final days = await daysOf(enrollment.id);
      expect(days.first.status, DayStatus.completed);
      expect(days.first.size, DaySize.standard, reason: 'gedaan blijft gedaan');
      expect(days.skip(1).every((d) => d.size == DaySize.smaller), isTrue);
    });
  });
}
