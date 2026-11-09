import '../database/app_database.dart';
import '../database/enums.dart';
import '../database/local_types.dart';

/// Een dag in de strook van de afgelopen week.
class MomentDay {
  const MomentDay({required this.date, required this.weekday, required this.moments});

  /// Lokale kalenderdatum, `YYYY-MM-DD`.
  final String date;

  /// 1 (maandag) tot en met 7 (zondag).
  final int weekday;

  /// Afgeronde momenten die dag.
  final int moments;
}

/// De stand van een stap uit het plan.
class StepDay {
  const StepDay({
    required this.dayNumber,
    required this.status,
    required this.size,
    required this.scheduledFor,
  });

  final int dayNumber;
  final DayStatus status;

  /// `smaller` als de stap is ingekort.
  final DaySize size;
  final String scheduledFor;
}

/// Overzicht van wat de app nu bijhoudt.
class ProgressSummary {
  const ProgressSummary({
    required this.completedMoments,
    required this.completedMomentsLast7Days,
    required this.protectedSeconds,
    required this.stepsCompleted,
    required this.stepsTotal,
    required this.plannedMoments,
    required this.plannedSeconds,
    required this.plannedActualSeconds,
    required this.plannedFullLength,
    required this.last7Days,
    required this.daysWithMoment,
    required this.stepDays,
    required this.blockedSeconds,
    required this.blockedSecondsLast7Days,
  });

  /// Afgeronde beschermde momenten (uitkomst `completed`).
  final int completedMoments;
  final int completedMomentsLast7Days;

  /// Totale tijd van die momenten, van start tot einde.
  final int protectedSeconds;

  final int stepsCompleted;
  final int stepsTotal;

  /// Afgeronde momenten met een geplande duur, en hun geplande en werkelijke
  /// tijd. `plannedFullLength` telt de momenten die minstens zo lang duurden.
  final int plannedMoments;
  final int plannedSeconds;
  final int plannedActualSeconds;
  final int plannedFullLength;

  /// De laatste 7 dagen, oudste eerst, de laatste is vandaag.
  final List<MomentDay> last7Days;

  /// Aantal verschillende dagen met minstens een afgerond moment.
  final int daysWithMoment;

  /// Alle stappen van het plan, op volgorde van dag.
  final List<StepDay> stepDays;

  /// Tijd dat blokkeren aantoonbaar aan stond: van bevestigd tot vrijgegeven
  /// (of het einde van de sessie). Telt ook sessies die eerder zijn gestopt.
  final int blockedSeconds;
  final int blockedSecondsLast7Days;

  factory ProgressSummary.build({
    required List<FocusSession> sessions,
    required List<ProgrammeDay> days,
    required DateTime now,
  }) {
    final done = sessions
        .where((s) => s.outcome == SessionOutcome.completed && s.endedAt != null)
        .toList();
    final today = DateTime(now.year, now.month, now.day);
    final week = [
      for (var i = 6; i >= 0; i--) DateTime(today.year, today.month, today.day - i),
    ];
    final since = LocalDate.format(week.first);
    final blocked = [
      for (final s in sessions)
        if (s.blockingConfirmedAt != null &&
            (s.blockingReleasedAt ?? s.endedAt) != null)
          (
            localDate: s.localDate,
            seconds: (s.blockingReleasedAt ?? s.endedAt)!
                .difference(s.blockingConfirmedAt!)
                .inSeconds
                .clamp(0, 1 << 30),
          ),
    ];
    final planned = done.where((s) => (s.plannedSeconds ?? 0) > 0).toList();
    int actual(FocusSession s) => s.endedAt!.difference(s.startedAt).inSeconds;
    final orderedDays = [...days]..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    final seconds = done.fold<int>(
      0,
      (sum, s) => sum + s.endedAt!.difference(s.startedAt).inSeconds,
    );

    return ProgressSummary(
      completedMoments: done.length,
      completedMomentsLast7Days:
          done.where((s) => s.localDate.compareTo(since) >= 0).length,
      protectedSeconds: seconds < 0 ? 0 : seconds,
      stepsCompleted:
          days.where((d) => d.status == DayStatus.completed).length,
      stepsTotal: days.length,
      plannedMoments: planned.length,
      plannedSeconds: planned.fold(0, (sum, s) => sum + s.plannedSeconds!),
      plannedActualSeconds: planned.fold(0, (sum, s) => sum + actual(s)),
      plannedFullLength:
          planned.where((s) => actual(s) >= s.plannedSeconds!).length,
      last7Days: [
        for (final d in week)
          MomentDay(
            date: LocalDate.format(d),
            weekday: d.weekday,
            moments: done.where((s) => s.localDate == LocalDate.format(d)).length,
          ),
      ],
      daysWithMoment: done.map((s) => s.localDate).toSet().length,
      stepDays: [
        for (final d in orderedDays)
          StepDay(
            dayNumber: d.dayNumber,
            status: d.status,
            size: d.size,
            scheduledFor: d.scheduledFor,
          ),
      ],
      blockedSeconds: blocked.fold(0, (sum, b) => sum + b.seconds),
      blockedSecondsLast7Days: blocked
          .where((b) => b.localDate.compareTo(since) >= 0)
          .fold(0, (sum, b) => sum + b.seconds),
    );
  }
}
