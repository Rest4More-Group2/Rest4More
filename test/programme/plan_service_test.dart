import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/intake/intake_service.dart';
import 'package:rest4more/data/programme/content_catalog.dart';
import 'package:rest4more/data/programme/plan_scheduler.dart';
import 'package:rest4more/data/programme/plan_service.dart';
import 'package:rest4more/data/programme/today_plan.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/data/repositories/programme_repository.dart';

import '../data/test_support.dart';

Future<ContentCatalog> loadFromFile() async => ContentCatalog.parse(
    File('assets/programme/programme_content.json').readAsStringSync());

void main() {
  late AppDatabase db;
  late IntakeService intake;
  late TestClock clock;
  late PlanService plans;

  setUp(() {
    db = memoryDb();
    clock = TestClock(DateTime(2026, 3, 2, 18));
    intake = IntakeService(ProfileRepository(db, now: clock.call));
    plans = PlanService(db, loadFromFile, now: clock.call);
  });
  tearDown(() => db.close());

  Future<void> finishOnboarding({int goal = 0, bool reminder = true}) async {
    await intake.saveGoal(goal);
    await intake.saveObstacles([0]);
    await intake.saveRhythm(1);
    await intake.saveActivities([1]);
    await intake.savePlanSeen();
    await intake.complete(
      reminderEnabled: reminder,
      reminderMinutes: reminder ? 22 * 60 : null,
    );
  }

  test('geen plan zolang de onboarding niet af is', () async {
    await intake.saveGoal(0);
    expect(await plans.ensurePlan(), isFalse);
    expect(await db.select(db.programmeEnrollments).get(), isEmpty);
  });

  test('na de onboarding ontstaat een deelname met veertien dagen', () async {
    await finishOnboarding(goal: 1);
    expect(await plans.ensurePlan(), isTrue);

    final enrollment = await db.select(db.programmeEnrollments).getSingle();
    expect(enrollment.status, EnrollmentStatus.active);
    expect(enrollment.contentVersion, '1.0-en');
    expect(enrollment.selection['goal'], 'routine');
    expect(enrollment.selection['obstacle'], 'scrolling');
    expect(enrollment.selection['rules_version'], PlanService.rulesVersion);

    final days = await ProgrammeRepository(db).watchDays(enrollment.id).first;
    expect(days.map((d) => d.dayNumber), [for (var i = 1; i <= 14; i++) i]);
    expect(days.every((d) => d.status == DayStatus.planned), isTrue);
    expect(days.first.contentId, 'rfm-en-v1-d01-routine');
    expect(days.last.contentId, 'rfm-en-v1-d14-routine');
  });

  test('de dag bewaart de uitgewerkte inhoud als momentopname', () async {
    await finishOnboarding();
    await plans.ensurePlan();
    final day = (await db.select(db.programmeDays).get())
        .firstWhere((d) => d.dayNumber == 4);
    expect(day.snapshot['title'], 'Give the space a purpose');
    expect(day.snapshot['action'] as String, contains('a few pages'));
    expect(day.snapshot['obstacle_action'], isNotNull);
    expect(day.snapshot['why_this'], contains('scrolling'));
    expect(day.snapshot['smaller_action'], isNotEmpty);
  });

  test('de antwoorden uit de onboarding sturen de inhoud', () async {
    await finishOnboarding();
    await plans.ensurePlan();
    final days = await db.select(db.programmeDays).get();
    final day4 = days.firstWhere((d) => d.dayNumber == 4).snapshot['action'] as String;
    expect(day4, contains('reading a few pages'), reason: 'papieren lezen gekozen');
    expect(day4, contains('your book'));
  });

  test('datums: begint morgen als de herinnering te dichtbij is', () async {
    // 18:00 nu, herinnering 22:00: ruim een uur weg, dus vandaag.
    await finishOnboarding();
    await plans.ensurePlan();
    var days = await db.select(db.programmeDays).get()
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    expect(days.first.scheduledFor, '2026-03-02');
    expect(days.last.scheduledFor, '2026-03-15');
  });

  test('datums: herinnering binnen het uur geeft morgen', () async {
    clock.current = DateTime(2026, 3, 2, 21, 30);
    await finishOnboarding();
    await plans.ensurePlan();
    final days = await db.select(db.programmeDays).get()
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    expect(days.first.scheduledFor, '2026-03-03');
    expect((await db.select(db.programmeEnrollments).getSingle()).startedOn, '2026-03-03');
  });

  test('zonder herinnering begint het vandaag', () async {
    clock.current = DateTime(2026, 3, 2, 23, 0);
    await finishOnboarding(reminder: false);
    await plans.ensurePlan();
    final days = await db.select(db.programmeDays).get()
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    expect(days.first.scheduledFor, '2026-03-02');
  });

  test('een tweede keer maakt geen dubbel plan', () async {
    await finishOnboarding();
    expect(await plans.ensurePlan(), isTrue);
    expect(await plans.ensurePlan(), isFalse);
    expect(await db.select(db.programmeEnrollments).get(), hasLength(1));
    expect(await db.select(db.programmeDays).get(), hasLength(14));
  });

  test('een fout bij het laden van de inhoud laat niets achter', () async {
    await finishOnboarding();
    final broken = PlanService(db, () async => throw StateError('geen bestand'),
        now: clock.call);
    await expectLater(broken.ensurePlan(), throwsStateError);
    expect(await db.select(db.programmeEnrollments).get(), isEmpty);
    expect(await db.select(db.programmeDays).get(), isEmpty);
    // Daarna lukt het alsnog.
    expect(await plans.ensurePlan(), isTrue);
  });

  test('het plan blijft behouden na heropenen van de database', () async {
    await finishOnboarding();
    await plans.ensurePlan();
    final reopened = PlanService(db, loadFromFile, now: clock.call);
    expect(await reopened.ensurePlan(), isFalse);
  });

  test('korte stap als standaard geeft kleine dagen', () async {
    await ProfileRepository(db).upsert(const ProfileDraft(stepSize: StepSize.short));
    await finishOnboarding();
    await plans.ensurePlan();
    final days = await db.select(db.programmeDays).get();
    expect(days.every((d) => d.size == DaySize.smaller), isTrue);
  });

  group('Today', () {
    late ProgrammeRepository programme;

    Future<List<ProgrammeDay>> planned() async {
      await finishOnboarding();
      await plans.ensurePlan();
      programme = ProgrammeRepository(db, now: clock.call);
      return db.select(db.programmeDays).get();
    }

    Future<void> complete(List<ProgrammeDay> days, Iterable<int> numbers) async {
      for (final n in numbers) {
        await programme.markCompleted(
            days.firstWhere((d) => d.dayNumber == n).id);
      }
    }

    test('een nieuw plan begint bij dag 1', () async {
      final today = pickToday(await planned())!;
      expect(today.day, 1);
      expect(today.totalDays, 14);
      expect(today.finished, isFalse);
      expect(today.title, 'Your starting point');
      expect(today.explanation, contains('This fits your goal'));
      expect(today.minutes, TodayPlan.defaultMinutes);
    });

    test('de volgende stap is de eerste die nog niet gedaan is', () async {
      final days = await planned();
      await complete(days, [1, 2, 3]);
      final today = pickToday(await db.select(db.programmeDays).get())!;
      expect(today.day, 4);
      expect(today.title, 'Give the space a purpose');
      expect(today.action, contains('reading a few pages'));
    });

    test('dagen niets doen verandert de stap niet, de datums tellen niet mee',
        () async {
      final days = await planned();
      await complete(days, [1]);
      // De datums liggen ver in het verleden: er verandert niets.
      await db.customStatement("UPDATE programme_days SET scheduled_for = '2020-01-01'");
      expect(pickToday(await db.select(db.programmeDays).get())!.day, 2);
    });

    test('een geopende maar niet afgeronde stap blijft de huidige', () async {
      final days = await planned();
      await programme.markOpened(days.firstWhere((d) => d.dayNumber == 1).id);
      final today = pickToday(await db.select(db.programmeDays).get())!;
      expect(today.day, 1);
      expect(today.status, DayStatus.opened);
    });

    test('een overgeslagen stap telt als gedaan', () async {
      final days = await planned();
      await programme.skip(days.firstWhere((d) => d.dayNumber == 1).id);
      expect(pickToday(await db.select(db.programmeDays).get())!.day, 2);
    });

    test('een lege plek vooraan wordt niet overgeslagen', () async {
      // Dag 3 afgerond zonder 1 en 2: de eerste open stap is nog dag 1.
      final days = await planned();
      await complete(days, [3]);
      expect(pickToday(await db.select(db.programmeDays).get())!.day, 1);
    });

    test('alles gedaan: de laatste dag met finished', () async {
      final days = await planned();
      await complete(days, [for (var i = 1; i <= 14; i++) i]);
      final today = pickToday(await db.select(db.programmeDays).get())!;
      expect(today.finished, isTrue);
      expect(today.day, 14);
    });

    test('kleine stap als gekozen formaat geeft de kleine duur', () async {
      final days = await planned();
      await programme.setSize(days.first.id, DaySize.smaller);
      final today = pickToday(await db.select(db.programmeDays).get())!;
      expect(today.minutes, TodayPlan.defaultSmallerMinutes);
    });

    test('zonder plan is er niets', () {
      expect(pickToday(const []), isNull);
    });

    test('begroeting volgt het uur', () {
      expect(greetingFor(DateTime(2026, 3, 2, 8)), 'Good morning');
      expect(greetingFor(DateTime(2026, 3, 2, 14)), 'Good afternoon');
      expect(greetingFor(DateTime(2026, 3, 2, 21)), 'Good evening');
    });

    test('de planning loopt veertien dagen', () {
      expect(planLength, 14);
    });
  });
}
