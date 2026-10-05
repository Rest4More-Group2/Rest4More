import '../database/app_database.dart';
import '../database/converters.dart';
import '../database/enums.dart';
import '../database/local_types.dart';
import '../repositories/accessory_repository.dart';
import '../repositories/block_profile_repository.dart';
import '../repositories/focus_session_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/programme_repository.dart';
import '../repositories/routine_repository.dart';

/// Vult elke gesynchroniseerde tabel met een voorbeeldrij, om de push naar de
/// server te testen. Alleen voor debugbuilds. Doet niets als dit al eerder is
/// gedaan, zodat herstarten geen dubbele rijen maakt.
Future<bool> seedDebugData(AppDatabase db, {DateTime Function()? now}) async {
  final clock = now ?? DateTime.now;
  const marker = 'Debug routine';
  final existing = await (db.select(db.routines)
        ..where((t) => t.name.equals(marker)))
      .get();
  if (existing.isNotEmpty) return false;

  await ProfileRepository(db, now: clock).upsert(const ProfileDraft(
    displayName: 'Debug',
    ageBand: AgeBand.age25To39,
    primaryGoal: PrimaryGoal.phone,
    obstacle: Obstacle.scrolling,
    rhythm: Rhythm.regular,
    bedtimeMinutes: 23 * 60,
    timezone: 'Europe/Amsterdam',
  ));

  final block = await BlockProfileRepository(db, now: clock).create(
    name: 'Debug blokkeerprofiel',
    context: BlockContext.evening,
    items: const [
      BlockItemData(kind: BlockItemKind.url, value: 'example.com'),
      BlockItemData(
        kind: BlockItemKind.androidPackage,
        value: 'com.example.app',
        rule: BlockItemRule.allow,
      ),
    ],
  );

  final routines = RoutineRepository(db, now: clock);
  final routine = await routines.create(
    mode: 'evening',
    name: marker,
    endRule: RoutineEndRule.timer,
    defaultMinutes: 20,
    blockProfileId: block.id,
  );
  await routines.setSteps(routine.id, const [
    RoutineStepData(title: 'Lezen', durationMin: 10),
    RoutineStepData(title: 'Stil zitten', durationMin: 5),
  ]);
  await routines.setSchedule(
    routine.id,
    WeekdayMask.fromWeekdays({1, 2, 3, 4, 5}),
    21 * 60,
    false,
  );

  final card = await AccessoryRepository(db, now: clock).pairCard(
    tokenHash: AccessoryRepository.hashToken(
      'debug-${clock().microsecondsSinceEpoch}',
    ),
    label: 'Debugkaart',
  );

  final sessions = FocusSessionRepository(db, now: clock);
  if (await sessions.findOpen() == null) {
    final session = await sessions.start(
      mode: 'evening',
      source: SessionSource.manual,
      platform: SessionPlatform.ios,
      routineId: routine.id,
      blockProfileId: block.id,
      accessoryId: card.id,
      plannedSeconds: 1200,
    );
    await sessions.transition(session.id, SessionState.awaitingScan);
    await sessions.transition(session.id, SessionState.activating);
    await sessions.markBlockingConfirmed(session.id);
    await sessions.transition(session.id, SessionState.active);
    await sessions.transition(session.id, SessionState.releasing);
    await sessions.markBlockingReleased(session.id);
    await sessions.finish(
      session.id,
      SessionOutcome.completed,
      feeling: SessionFeeling.good,
    );
  }

  final programme = ProgrammeRepository(db, now: clock);
  final today = clock();
  final enrollment = await programme
      .enroll(
        contentVersion: 'debug-v1',
        selection: const {'goal': 'phone', 'step': 'short'},
        startedOn: today,
      )
      .then<ProgrammeEnrollment?>((value) => value)
      .catchError((Object _) => null, test: (e) => e is AlreadyEnrolledError);
  if (enrollment != null) {
    await programme.createDays(enrollment.id, [
      for (var i = 1; i <= 14; i++)
        DaySeed(
          dayNumber: i,
          contentId: 'debug-day-$i',
          scheduledFor: DateTime(today.year, today.month, today.day + i - 1),
          snapshot: {'title': 'Dag $i'},
        ),
    ]);
    final days = await programme.watchDays(enrollment.id).first;
    await programme.markOffered(days.first.id);
    await programme.markOpened(days.first.id);
    await programme.markCompleted(days.first.id);
    await programme.recordCheckin(days.first.id,
        fit: DayFit.partly, blocker: DayBlocker.time);
    await programme.recordMorningCheck(days.first.id,
        protected: DayProtected.yes, restedScore: 4);
  }
  return true;
}
