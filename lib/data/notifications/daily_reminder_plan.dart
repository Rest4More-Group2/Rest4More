import '../database/app_database.dart';
import '../database/enums.dart';
import '../database/local_types.dart';

/// Een herinnering voor de dagelijkse stap op een bepaalde dag.
class DailyReminder {
  const DailyReminder({
    required this.date,
    required this.minutes,
    required this.programmeDayId,
    required this.day,
    required this.totalDays,
    required this.stepTitle,
  });

  /// Lokale kalenderdatum.
  final DateTime date;

  /// Minuten sinds middernacht, lokale tijd.
  final int minutes;
  final String programmeDayId;
  final int day;
  final int totalDays;
  final String stepTitle;

  /// Een vaste id per datum (`YYYYMMDD`), zodat er nooit twee op een dag staan.
  int get id => date.year * 10000 + date.month * 100 + date.day;

  String get title => 'Your step for today';

  String get body => stepTitle.isEmpty
      ? 'Day $day of $totalDays is ready when you are.'
      : 'Day $day of $totalDays: $stepTitle';
}

/// Hoeveel dagen vooruit er herinneringen klaarstaan. De planning wordt
/// opnieuw gemaakt elke keer dat de app opent of er een stap is gedaan, dus
/// dit hoeft alleen een paar dagen zonder de app te overbruggen. iOS houdt er
/// maximaal 64 vast.
const reminderHorizonDays = 14;

/// Welke herinneringen er moeten klaarstaan, vanaf [now].
///
/// - Eén per dag, op [minutes].
/// - Niet vandaag als de stap van vandaag al gedaan is of het tijdstip voorbij
///   is.
/// - Niet voor de eerste dag van het plan.
/// - Elke herinnering noemt de eerstvolgende stap die nog niet gedaan is: het
///   plan loopt dag voor dag door, ook als er dagen niets gebeurt. Wordt er een
///   stap gedaan, dan wordt dit opnieuw berekend en schuift de volgende door.
/// - Niets als alle stappen gedaan zijn.
List<DailyReminder> planDailyReminders({
  required List<ProgrammeDay> days,
  required int minutes,
  required DateTime now,
  int horizon = reminderHorizonDays,
}) {
  final usable = [
    for (final d in days)
      if (d.deletedAt == null) d,
  ]..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
  bool done(ProgrammeDay d) =>
      d.status == DayStatus.completed || d.status == DayStatus.skipped;
  final next = usable.where((d) => !done(d)).firstOrNull;
  if (next == null) return const [];

  final today = DateTime(now.year, now.month, now.day);
  final doneToday = usable.any((d) {
    final at = d.completedAt?.toLocal();
    return at != null && DateTime(at.year, at.month, at.day) == today;
  });

  var first = today;
  final planStart = LocalDate.parse(usable.first.scheduledFor);
  if (planStart != null && planStart.isAfter(first)) first = planStart;
  final timePassed = now.hour * 60 + now.minute >= minutes;
  if (first == today && (doneToday || timePassed)) {
    first = DateTime(today.year, today.month, today.day + 1);
  }

  final title = (next.snapshot['title'] as String?) ?? '';
  return [
    for (var i = 0; i < horizon; i++)
      DailyReminder(
        date: DateTime(first.year, first.month, first.day + i),
        minutes: minutes,
        programmeDayId: next.id,
        day: next.dayNumber,
        totalDays: usable.length,
        stepTitle: title,
      ),
  ];
}
