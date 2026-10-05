import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/intake/intake_service.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';

import 'test_support.dart';

void main() {
  late AppDatabase db;
  late ProfileRepository profiles;
  late IntakeService intake;

  setUp(() {
    db = memoryDb();
    profiles = ProfileRepository(db);
    intake = IntakeService(profiles);
  });
  tearDown(() => db.close());

  test('een nieuw profiel begint bij de welkomstpagina', () async {
    final progress = await intake.load();
    expect(progress.step, OnboardingStep.welcome);
    expect(progress.goal, isNull);
    expect(progress.completed, isFalse);
  });

  test('elke keuze wordt bewaard en teruggelezen als dezelfde index', () async {
    for (var i = 0; i < IntakeMapping.goals.length; i++) {
      await intake.saveGoal(i);
      expect((await intake.load()).goal, i);
      expect((await profiles.get()).primaryGoal, IntakeMapping.goals[i]);
    }
    for (var i = 0; i < IntakeMapping.obstacles.length; i++) {
      await intake.saveObstacles([i]);
      expect((await intake.load()).obstacle, i);
    }
    for (var i = 0; i < IntakeMapping.windDownStartMinutes.length; i++) {
      await intake.saveRhythm(i);
      expect((await intake.load()).rhythm, i, reason: 'venster $i');
    }
    for (var i = 0; i < IntakeMapping.activities.length; i++) {
      await intake.saveActivities([i]);
      expect((await intake.load()).activity, i);
    }
  });

  test('de obstakels hebben dezelfde id als de inhoud van het programma', () {
    expect(IntakeMapping.obstacles.map((o) => o.id),
        ['scrolling', 'availability', 'thoughts', 'planning', 'alarm', 'no_routine']);
    expect(IntakeMapping.goals.map((g) => g.id), ['phone', 'routine', 'social']);
  });

  test('na middernacht (0 minuten) is niet hetzelfde als niet beantwoord',
      () async {
    expect((await intake.load()).rhythm, isNull);
    await intake.saveRhythm(2);
    expect((await profiles.get()).bedtimeMinutes, 0);
    expect((await intake.load()).rhythm, 2);
  });

  test('bij meerdere keuzes telt de eerste', () async {
    await intake.saveObstacles([3, 0, 5]);
    expect((await profiles.get()).obstacle, Obstacle.planning);
    await intake.saveActivities([2, 1]);
    expect((await profiles.get()).preferredActivity, PreferredActivity.breathing);
  });

  test('geen keuze overschrijft een eerder antwoord niet', () async {
    await intake.saveObstacles([1]);
    await intake.saveObstacles([]);
    expect((await profiles.get()).obstacle, Obstacle.availability);
  });

  test('een onbestaande optie wordt geweigerd en schrijft niets', () async {
    await expectLater(intake.saveGoal(3), throwsRangeError);
    await expectLater(intake.saveGoal(-1), throwsRangeError);
    expect((await profiles.get()).primaryGoal, isNull);
    expect((await profiles.get()).intakeStep, 0);
  });

  test('hervatten: elk opgeslagen scherm geeft het volgende scherm', () async {
    await intake.saveGoal(0);
    expect((await intake.load()).step, OnboardingStep.obstacle);
    await intake.saveObstacles([0]);
    expect((await intake.load()).step, OnboardingStep.rhythm);
    await intake.saveRhythm(1);
    expect((await intake.load()).step, OnboardingStep.activities);
    await intake.saveActivities([0]);
    expect((await intake.load()).step, OnboardingStep.plan);
    await intake.savePlanSeen();
    expect((await intake.load()).step, OnboardingStep.reminder);
  });

  test('afronden met herinnering bewaart tijd en zet de intake op klaar',
      () async {
    await intake.complete(reminderEnabled: true, reminderMinutes: 22 * 60);
    final progress = await intake.load();
    expect(progress.completed, isTrue);
    expect(progress.step, OnboardingStep.done);
    expect(progress.reminderEnabled, isTrue);
    expect(progress.reminderMinutes, 1320);
  });

  test('afronden zonder herinnering plant niets in', () async {
    await intake.complete(reminderEnabled: false, reminderMinutes: 22 * 60);
    final progress = await intake.load();
    expect(progress.completed, isTrue);
    expect(progress.reminderEnabled, isFalse);
    expect(progress.reminderMinutes, isNull);
  });

  test('een ongeldige herinneringstijd wordt geweigerd', () async {
    await expectLater(
      intake.complete(reminderEnabled: true, reminderMinutes: 1440),
      throwsA(anything),
    );
    expect((await intake.load()).completed, isFalse);
  });

  test('antwoorden overleven het heropenen van de database', () async {
    await intake.saveGoal(2);
    await intake.saveObstacles([4]);
    final again = IntakeService(ProfileRepository(db));
    final progress = await again.load();
    expect(progress.goal, 2);
    expect(progress.obstacle, 4);
    expect(progress.step, OnboardingStep.rhythm);
  });
}
