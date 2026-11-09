import '../../l10n/app_localizations.dart';
import '../../l10n/plan_labels.dart';
import '../database/app_database.dart';
import '../database/enums.dart';

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
    this.finished = false,
    this.waitingForTomorrow = false,
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

  /// Alle dagen zijn gedaan. De rest van dit object beschrijft de laatste dag.
  final bool finished;

  /// Er is vandaag al een stap gedaan. Eén stap per dag: deze is voor morgen.
  final bool waitingForTomorrow;

  /// Standaardduur van een stap, tot de gebruiker er zelf een kiest. Het
  /// programma beschrijft acties, geen minuten.
  static const defaultMinutes = 20;
  static const defaultSmallerMinutes = 5;
}

/// De eerstvolgende stap die nog niet is gedaan, maximaal één per dag. Het plan
/// loopt dag voor dag:
/// wie een paar dagen niets doet, gaat gewoon verder waar hij was gebleven. De
/// datums in het plan bepalen dit niet. Afgeronde en overgeslagen dagen tellen
/// als gedaan. Is alles gedaan, dan is dit de laatste dag met [TodayPlan.finished].
///
/// [localized] heeft per dagnummer de tekst van die dag in de huidige taal. Die
/// gaat voor op wat bij het maken van het plan is bewaard, zodat een plan van
/// taal wisselt als de gebruiker dat doet.
TodayPlan? pickToday(
  List<ProgrammeDay> days,
  DateTime now, {
  Map<int, Map<String, Object?>> localized = const {},
}) {
  final usable = [
    for (final d in days)
      if (d.deletedAt == null) d,
  ]..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
  if (usable.isEmpty) return null;

  bool done(ProgrammeDay d) =>
      d.status == DayStatus.completed || d.status == DayStatus.skipped;
  final next = usable.where((d) => !done(d)).firstOrNull;
  // Eén stap per kalenderdag (lokale tijd): is er vandaag al een afgerond, dan
  // wacht de volgende tot morgen.
  final today = DateTime(now.year, now.month, now.day);
  final doneToday = usable.any((d) {
    final at = d.completedAt?.toLocal();
    return at != null && DateTime(at.year, at.month, at.day) == today;
  });
  final chosen = next ?? usable.last;

  final content = localized[chosen.dayNumber] ?? chosen.snapshot;
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
    finished: next == null,
    waitingForTomorrow: next != null && doneToday,
  );
}

/// Begroeting bij het uur van de dag.
String greetingFor(DateTime now, [AppLocalizations? l10n]) {
  final t = l10n ?? englishL10n();
  if (now.hour < 12) return t.greetingMorning;
  if (now.hour < 18) return t.greetingAfternoon;
  return t.greetingEvening;
}
