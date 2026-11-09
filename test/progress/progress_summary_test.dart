import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/progress/progress_summary.dart';
import 'package:rest4more/data/repositories/focus_session_repository.dart';
import 'package:rest4more/data/repositories/programme_repository.dart';

import '../data/test_support.dart';

void main() {
  test('leeg: nullen en geen gemiddelde', () {
    final s = ProgressSummary.build(
      sessions: const [],
      days: const [],
      now: DateTime(2026, 3, 10),
    );
    expect(s.completedMoments, 0);
    expect(s.stepsTotal, 0);
    expect(s.blockedSeconds, 0);
  });

  test('telt alleen afgeronde momenten en afgeronde stappen', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final clock = TestClock(DateTime(2026, 3, 10, 20));
    final sessions = FocusSessionRepository(db, now: clock.call);

    final ok = await startSession(sessions, upTo: SessionState.active);
    clock.advance(const Duration(minutes: 30));
    await sessions.transition(ok.id, SessionState.releasing);
    await sessions.finish(ok.id, SessionOutcome.completed);

    final early = await startSession(sessions, upTo: SessionState.active);
    await sessions.transition(early.id, SessionState.emergency);
    await sessions.transition(early.id, SessionState.releasing);
    await sessions.finish(early.id, SessionOutcome.emergencyRelease);

    final programme = ProgrammeRepository(db);
    final enrollmentId = await enrollWithDays(programme);
    final days = await programme.days(enrollmentId);
    await programme.markCompleted(days[0].id);

    final s = ProgressSummary.build(
      sessions: await sessions.watchHistory().first,
      days: await programme.days(enrollmentId),
      now: clock.call(),
    );

    expect(s.completedMoments, 1);
    expect(s.completedMomentsLast7Days, 1);
    expect(s.protectedSeconds, 30 * 60);
    expect(s.stepsCompleted, 1);
    expect(s.stepsTotal, 14);
  });

  test('gepland tegenover werkelijk, dagen met een moment en stapstatus',
      () async {
    final db = memoryDb();
    addTearDown(db.close);
    final clock = TestClock(DateTime(2026, 3, 10, 20));
    final sessions = FocusSessionRepository(db, now: clock.call);

    Future<void> run(Duration length, int plannedMinutes) async {
      final session = await sessions.start(
        mode: 'focus',
        source: SessionSource.manual,
        platform: SessionPlatform.android,
        plannedSeconds: plannedMinutes * 60,
      );
      await sessions.transition(session.id, SessionState.activating);
      await sessions.markBlockingConfirmed(session.id);
      await sessions.transition(session.id, SessionState.active);
      clock.advance(length);
      await sessions.transition(session.id, SessionState.releasing);
      await sessions.markBlockingReleased(session.id);
      await sessions.finish(session.id, SessionOutcome.completed);
    }

    await run(const Duration(minutes: 30), 30); // vol
    await run(const Duration(minutes: 10), 20); // korter
    clock.current = DateTime(2026, 3, 8, 20);
    await run(const Duration(minutes: 5), 5); // twee dagen eerder

    final programme = ProgrammeRepository(db);
    final enrollmentId = await enrollWithDays(programme);
    final days = await programme.days(enrollmentId);
    await programme.markCompleted(days[0].id);
    await programme.skip(days[1].id);

    final s = ProgressSummary.build(
      sessions: await sessions.watchHistory().first,
      days: await programme.days(enrollmentId),
      now: DateTime(2026, 3, 10, 21),
    );

    expect(s.plannedMoments, 3);
    expect(s.plannedSeconds, 55 * 60);
    expect(s.plannedActualSeconds, 45 * 60);
    expect(s.plannedFullLength, 2);
    expect(s.blockedSeconds, 45 * 60);
    expect(s.blockedSecondsLast7Days, 45 * 60);

    expect(s.daysWithMoment, 2);
    expect(s.last7Days, hasLength(7));
    expect(s.last7Days.last.date, '2026-03-10');
    expect(s.last7Days.last.moments, 2);
    expect(s.last7Days[4].date, '2026-03-08');
    expect(s.last7Days[4].moments, 1);
    expect(s.last7Days[5].moments, 0);

    expect(s.stepDays, hasLength(14));
    expect(s.stepDays[0].status, DayStatus.completed);
    expect(s.stepDays[1].status, DayStatus.skipped);
    expect(s.stepDays[2].status, DayStatus.planned);
  });
}
