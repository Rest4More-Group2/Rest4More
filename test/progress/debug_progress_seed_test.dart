import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/progress/debug_progress_seed.dart';
import 'package:rest4more/data/progress/progress_summary.dart';
import 'package:rest4more/data/programme/content_catalog.dart';
import 'package:rest4more/data/repositories/focus_session_repository.dart';
import 'package:rest4more/data/repositories/programme_repository.dart';

import '../data/test_support.dart';

void main() {
  test('de voorbeelddata geeft een gevuld Progress-scherm', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final now = DateTime(2026, 3, 10, 12);
    await seedProgressDemo(
      db,
      () async => ContentCatalog.parse(
        File('assets/programme/programme_content.json').readAsStringSync(),
      ),
      now: () => now,
    );

    final programme = ProgrammeRepository(db);
    final enrollment = (await programme.activeEnrollment())!;
    final days = await programme.days(enrollment.id);
    final s = ProgressSummary.build(
      sessions: await FocusSessionRepository(db).watchHistory().first,
      days: days,
      now: now,
    );

    expect(days, hasLength(14));
    expect(days.first.scheduledFor, '2026-03-02');
    expect(s.stepsCompleted, 5);
    expect(s.stepDays.map((d) => d.status).toSet(), containsAll([
      DayStatus.completed,
      DayStatus.skipped,
      DayStatus.offered,
    ]));
    expect(
      s.stepDays.where((d) => d.size == DaySize.smaller).map((d) => d.dayNumber),
      [2, 4, 5, 6, 7],
    );
    expect(s.completedMoments, 7);
    expect(s.completedMomentsLast7Days, 6);
    expect(s.daysWithMoment, 6);
    expect(s.last7Days.last.moments, 1, reason: 'vandaag');
    expect(s.plannedMoments, 7);
    // Zeven afgeronde momenten (20+20+30+12+10+20+20 min) en de noodstop van
    // 8 min: ook die tijd stond blokkeren aan.
    expect(s.blockedSeconds, (20 + 20 + 30 + 12 + 10 + 20 + 8 + 20) * 60);
  });
}
