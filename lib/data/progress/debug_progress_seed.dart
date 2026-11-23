import 'dart:math';

import '../database/app_database.dart';
import '../database/enums.dart';
import '../intake/intake_service.dart';
import '../programme/content_catalog.dart';
import '../programme/plan_service.dart';
import '../repositories/focus_session_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/programme_repository.dart';
import '../repositories/session_end_reason_repository.dart';

/// Een voorbeeldmoment: hoeveel dagen geleden, hoe laat, geplande en
/// werkelijke minuten en hoe het afliep.
typedef _Moment = ({
  int daysAgo,
  int hour,
  int planned,
  int actual,
  SessionOutcome outcome,
});

const _moments = <_Moment>[
  (daysAgo: 8, hour: 21, planned: 20, actual: 20, outcome: SessionOutcome.completed),
  (daysAgo: 6, hour: 21, planned: 20, actual: 20, outcome: SessionOutcome.completed),
  (daysAgo: 5, hour: 22, planned: 30, actual: 30, outcome: SessionOutcome.completed),
  (daysAgo: 3, hour: 21, planned: 20, actual: 12, outcome: SessionOutcome.completed),
  (daysAgo: 2, hour: 7, planned: 10, actual: 10, outcome: SessionOutcome.completed),
  (daysAgo: 2, hour: 21, planned: 20, actual: 20, outcome: SessionOutcome.completed),
  (daysAgo: 1, hour: 21, planned: 30, actual: 8, outcome: SessionOutcome.emergencyRelease),
];

/// Vult de database met voorbeelddata om het Progress-scherm te zien: een
/// afgeronde onboarding, het echte plan van 14 dagen dat 8 dagen geleden
/// begon met een mix van stapstatussen, en afgeronde momenten in de week
/// daarna, tot en met een moment van vandaag. Alleen voor debugbuilds, via `--dart-define=DEBUG_SEED_PROGRESS=true`.
/// Verwacht een lege database.
Future<void> seedProgressDemo(
  AppDatabase db,
  Future<ContentCatalog> Function() loadCatalog, {
  DateTime Function()? now,
  bool withMoments = true,
}) async {
  final clock = now ?? DateTime.now;
  final today = clock();
  DateTime at(int daysAgo, int hour, [int minute = 0]) =>
      DateTime(today.year, today.month, today.day - daysAgo, hour, minute);

  final profiles = ProfileRepository(db, now: clock);
  await profiles.upsert(const ProfileDraft(
    displayName: 'Demo',
    ageBand: AgeBand.age25To39,
  ));
  final intake = IntakeService(profiles);
  await intake.saveGoal(0);
  await intake.saveObstacles([0]);
  await intake.complete(reminderEnabled: false);

  // Het plan begint 8 dagen geleden, dus vandaag is dag 9.
  final planClock = at(8, 9);
  await PlanService(db, loadCatalog, now: () => planClock).ensurePlan();

  final programme = ProgrammeRepository(db, now: clock);
  final enrollment = (await programme.activeEnrollment())!;
  final days = await programme.days(enrollment.id);
  final byNumber = {for (final d in days) d.dayNumber: d};
  for (final n in [1, 2, 4, 6, 8]) {
    await programme.markCompleted(byNumber[n]!.id);
  }
  await programme.skip(byNumber[3]!.id);
  // Ingekorte stappen, alleen bij afgeronde dagen. Dag 5 en 7 zijn ook klein,
  // maar die tonen geen markering.
  for (final n in [2, 4, 5, 6, 7]) {
    await programme.setSize(byNumber[n]!.id, DaySize.smaller);
  }
  await programme.markOffered(byNumber[7]!.id);

  if (!withMoments) return;

  // Een moment van vandaag, dat net is afgelopen, zodat de week bij vandaag
  // eindigt.
  final todayMoment = (
    started: today.subtract(const Duration(minutes: 40)),
    planned: 20,
    actual: 20,
    outcome: SessionOutcome.completed,
  );
  final all = [
    for (final m in _moments)
      (
        started: at(m.daysAgo, m.hour),
        planned: m.planned,
        actual: m.actual,
        outcome: m.outcome,
      ),
    todayMoment,
  ];

  for (final m in all) {
    final started = m.started;
    var current = started;
    final sessions = FocusSessionRepository(db, now: () => current);
    final session = await sessions.start(
      mode: 'evening',
      source: SessionSource.manual,
      platform: SessionPlatform.android,
      plannedSeconds: m.planned * 60,
    );
    await sessions.transition(session.id, SessionState.activating);
    await sessions.markBlockingConfirmed(session.id);
    await sessions.transition(session.id, SessionState.active);
    current = started.add(Duration(minutes: m.actual));
    if (m.outcome == SessionOutcome.emergencyRelease) {
      await sessions.transition(session.id, SessionState.emergency);
    }
    await sessions.transition(session.id, SessionState.releasing);
    await sessions.markBlockingReleased(session.id);
    await sessions.finish(session.id, m.outcome);
  }
}

/// Ongeveer vier weken aan momenten voor het Progress-scherm (This week en
/// Patterns): meestal een avondmoment, in het weekend vaker overgeslagen of
/// eerder gestopt, vroege stops vooral laat op de avond en meestal met een
/// reden. Een paar ochtendmomenten zonder blokkade, zodat ook "sessietijd"
/// zichtbaar wordt. Vast zaad: elke keer dezelfde data.
///
/// Alleen voor debugbuilds, via `--dart-define=DEBUG_SEED_PROGRESS_WEEKS=true`.
Future<int> seedProgressWeeks(
  AppDatabase db, {
  DateTime Function()? now,
  int days = 28,
}) async {
  final clock = now ?? DateTime.now;
  final today = clock();
  final random = Random(7);
  final reasons = SessionEndReasonRepository(db);
  const reasonPool = [
    EndReason.couldntSleep,
    EndReason.couldntSleep,
    EndReason.couldntSleep,
    EndReason.neededPhone,
    EndReason.notification,
    EndReason.justWanted,
    null, // overgeslagen
  ];
  var count = 0;

  Future<void> add({
    required DateTime started,
    required int planned,
    required int actual,
    required bool early,
    required bool blocking,
    String mode = 'evening',
  }) async {
    var current = started;
    final sessions = FocusSessionRepository(db, now: () => current);
    final session = await sessions.start(
      mode: mode,
      source: SessionSource.manual,
      platform: SessionPlatform.android,
      plannedSeconds: planned * 60,
    );
    await sessions.transition(session.id, SessionState.activating);
    if (blocking) await sessions.markBlockingConfirmed(session.id);
    await sessions.transition(session.id, SessionState.active);
    current = started.add(Duration(minutes: actual));
    await sessions.transition(session.id, SessionState.releasing);
    if (blocking) await sessions.markBlockingReleased(session.id);
    await sessions.finish(
      session.id,
      early ? SessionOutcome.stoppedEarly : SessionOutcome.completed,
    );
    if (early) {
      await reasons.set(
        session.id,
        reasonPool[random.nextInt(reasonPool.length)],
      );
    }
    count++;
  }

  for (var back = days - 1; back >= 1; back--) {
    final day = DateTime(today.year, today.month, today.day - back);
    final weekend = day.weekday >= DateTime.saturday;
    // Weekend: vaker geen moment.
    if (random.nextDouble() < (weekend ? 0.35 : 0.1)) continue;

    final planned = [30, 45, 45, 60][random.nextInt(4)];
    final earlyChance = weekend ? 0.6 : 0.25;
    final early = random.nextDouble() < earlyChance;
    // Vroege stops vooral laat: begin rond 22:00 zodat het einde na 22:30 valt.
    final lateStart = early && random.nextDouble() < 0.7;
    final started = DateTime(
      day.year,
      day.month,
      day.day,
      lateStart ? 22 : 21,
      lateStart ? 10 + random.nextInt(30) : random.nextInt(40),
    );
    final actual = early ? 8 + random.nextInt(planned ~/ 2) : planned;
    await add(
      started: started,
      planned: planned,
      actual: actual,
      early: early,
      blocking: true,
    );

    // Af en toe een kort ochtendmoment zonder blokkade.
    if (!weekend && random.nextDouble() < 0.2) {
      await add(
        started: DateTime(day.year, day.month, day.day, 7, 15),
        planned: 10,
        actual: 10,
        early: false,
        blocking: false,
        mode: 'morning',
      );
    }
  }
  return count;
}
