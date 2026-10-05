import '../database/app_database.dart';
import '../database/enums.dart';
import '../database/local_types.dart';

/// Wat het Today-scherm toont voor de huidige dag.
class TodayPlan {
  const TodayPlan({
    required this.dayId,
    required this.day,
    required this.totalDays,
    required this.title,
    required this.action,
    required this.smallerAction,
    required this.explanation,
    required this.minutes,
    required this.smallerMinutes,
    required this.status,
  });

  final String dayId;
  final int day;
  final int totalDays;
  final String title;
  final String action;
  final String smallerAction;

  /// Waarom deze stap: uitleg plus wat bij de gebruiker past.
  final String explanation;
  final int minutes;
  final int smallerMinutes;
  final DayStatus status;

  /// Standaardduur van een stap, tot de gebruiker er zelf een kiest. Het
  /// programma beschrijft acties, geen minuten.
  static const defaultMinutes = 20;
  static const defaultSmallerMinutes = 5;
}

/// Welke dag hoort bij [now]. Vóór de eerste dag is dat dag 1, na de laatste
/// de laatste dag.
TodayPlan? pickToday(List<ProgrammeDay> days, DateTime now) {
  final usable = [
    for (final d in days)
      if (d.deletedAt == null) d,
  ]..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
  if (usable.isEmpty) return null;

  final today = LocalDate.format(now);
  ProgrammeDay chosen = usable.first;
  for (final d in usable) {
    // `scheduledFor` is `YYYY-MM-DD`, dus tekstvergelijking klopt.
    if (d.scheduledFor.compareTo(today) <= 0) chosen = d;
  }

  final content = chosen.snapshot;
  String text(String key) => (content[key] as String?) ?? '';
  final why = [text('explanation'), text('why_this')]
      .where((part) => part.isNotEmpty)
      .join('\n\n');
  return TodayPlan(
    dayId: chosen.id,
    day: chosen.dayNumber,
    totalDays: usable.length,
    title: text('title'),
    action: text('action'),
    smallerAction: text('smaller_action'),
    explanation: why,
    minutes: chosen.size == DaySize.smaller
        ? TodayPlan.defaultSmallerMinutes
        : TodayPlan.defaultMinutes,
    smallerMinutes: TodayPlan.defaultSmallerMinutes,
    status: chosen.status,
  );
}

/// Begroeting bij het uur van de dag.
String greetingFor(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 18) return 'Good afternoon';
  return 'Good evening';
}
