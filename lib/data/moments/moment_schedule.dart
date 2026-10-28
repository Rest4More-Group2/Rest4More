/// Rekenwerk voor de Avond- en Ochtendmomenten. Geen Flutter, geen database:
/// alleen tijden, zodat de dagwisseling goed te testen is.
library;

import '../database/converters.dart' show RoutineStepData;

/// Bedtijden tot dit tijdstip (exclusief) horen bij de avond ervoor. Wie om
/// 00:30 naar bed gaat, plant dat bij de avond van de dag ervoor.
const int afterMidnightCutoffMinutes = 6 * 60;

/// Of een bedtijd (minuten sinds middernacht) op de volgende kalenderdag valt.
bool isAfterMidnight(int minutes) => minutes < afterMidnightCutoffMinutes;

/// Hoe een strakke avondsessie eindigt. Een timer mag een strakke sessie nooit
/// stilletjes beëindigen: zonder scan blijft de blokkade staan.
enum EveningEnd {
  atBedtime('At bedtime'),
  atNextScan('At the next scan');

  const EveningEnd(this.label);
  final String label;
}

/// Eén avond in het weekschema. [weekday] is `DateTime.weekday` van de dag
/// waarop de avond begint, ook als de bedtijd na middernacht valt.
class EveningDay {
  const EveningDay({
    required this.weekday,
    this.enabled = true,
    this.bedtimeMinutes = 22 * 60 + 30,
  });

  final int weekday;
  final bool enabled;
  final int bedtimeMinutes;

  bool get bedtimeAfterMidnight => isAfterMidnight(bedtimeMinutes);

  EveningDay copyWith({bool? enabled, int? bedtimeMinutes}) => EveningDay(
        weekday: weekday,
        enabled: enabled ?? this.enabled,
        bedtimeMinutes: bedtimeMinutes ?? this.bedtimeMinutes,
      );
}

/// De drie momenten van een avond, als echte tijdstippen.
class EveningTimes {
  const EveningTimes({
    required this.windDown,
    required this.blockStart,
    required this.bedtime,
    required this.reminderIfNotStarted,
  });

  final DateTime windDown;
  final DateTime blockStart;
  final DateTime bedtime;

  /// `blockStart` plus de gratietijd: begint er dan nog geen sessie, dan komt
  /// er een luidere herinnering.
  final DateTime reminderIfNotStarted;
}

/// Telt terug vanaf de bedtijd. [eveningDate] is de kalenderdag waarop de
/// avond begint; alleen jaar, maand en dag tellen mee. Bij een bedtijd na
/// middernacht valt de bedtijd op de dag erna.
///
/// De dag erna wordt via de kalender bepaald (niet met `+ 24 uur`), en het
/// terugtellen gebeurt in echte minuten. Zo klopt het ook als de klok die
/// nacht verspringt.
EveningTimes eveningTimes({
  required DateTime eveningDate,
  required int bedtimeMinutes,
  required int windDownLeadMinutes,
  required int blockLeadMinutes,
  required int graceMinutes,
}) {
  final dayOffset = isAfterMidnight(bedtimeMinutes) ? 1 : 0;
  final bedtime = DateTime(
    eveningDate.year,
    eveningDate.month,
    eveningDate.day + dayOffset,
    bedtimeMinutes ~/ 60,
    bedtimeMinutes % 60,
  );
  // De blokstart ligt voor de bedtijd; het wind-down-moment ligt daar nog voor.
  final blockStart = bedtime.subtract(Duration(minutes: blockLeadMinutes));
  final windDown = blockStart.subtract(Duration(minutes: windDownLeadMinutes));
  return EveningTimes(
    windDown: windDown,
    blockStart: blockStart,
    bedtime: bedtime,
    reminderIfNotStarted: blockStart.add(Duration(minutes: graceMinutes)),
  );
}

/// Eén ochtend in het weekschema. [weekday] is de dag van het opstaan.
class MorningDay {
  const MorningDay({
    required this.weekday,
    this.enabled = true,
    this.wakeMinutes = 7 * 60,
  });

  final int weekday;
  final bool enabled;
  final int wakeMinutes;

  MorningDay copyWith({bool? enabled, int? wakeMinutes}) => MorningDay(
        weekday: weekday,
        enabled: enabled ?? this.enabled,
        wakeMinutes: wakeMinutes ?? this.wakeMinutes,
      );
}

/// Begin en einde van het ochtendblok op [morningDate].
({DateTime start, DateTime end}) morningWindow({
  required DateTime morningDate,
  required int wakeMinutes,
  required int blockMinutes,
}) {
  final start = DateTime(
    morningDate.year,
    morningDate.month,
    morningDate.day,
    wakeMinutes ~/ 60,
    wakeMinutes % 60,
  );
  return (start: start, end: start.add(Duration(minutes: blockMinutes)));
}

/// `HH:MM` voor minuten sinds middernacht.
String formatMinutes(int minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

/// `HH:MM` van een tijdstip.
String formatTime(DateTime t) => formatMinutes(t.hour * 60 + t.minute);

const List<String> weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Naam van een `DateTime.weekday` (1 tot en met 7).
String weekdayName(int weekday) => weekdayNames[weekday - 1];

/// Eén stap met een duur. Een stap zonder duur telt als [defaultStepMinutes].
int stepMinutes(RoutineStepData step) =>
    step.durationMin ?? defaultStepMinutes;

const int defaultStepMinutes = 5;
const int minStepMinutes = 5;
const int maxStepMinutes = 180;

/// Samen hoe lang de stappen duren.
int totalMinutes(List<RoutineStepData> steps) =>
    steps.fold(0, (sum, s) => sum + stepMinutes(s));

/// Wanneer elke stap begint, gerekend vanaf [start]. Het laatste element is het
/// einde van de routine.
List<DateTime> stepClock(DateTime start, List<RoutineStepData> steps) {
  final times = <DateTime>[start];
  for (final step in steps) {
    times.add(times.last.add(Duration(minutes: stepMinutes(step))));
  }
  return times;
}

/// "45 min", "1 h" of "1 h 05 min".
String formatDuration(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m min';
  if (m == 0) return '$h h';
  return '$h h ${m.toString().padLeft(2, '0')} min';
}

/// Waar de avond mee begint: samen precies een uur, dus bij een bedtijd van
/// 22:30 begint de avond om 21:30. De eerste stap is met opzet de telefoon
/// wegleggen.
const List<RoutineStepData> starterEveningSteps = [
  RoutineStepData(title: 'Put your phone away', durationMin: 5),
  RoutineStepData(title: 'Tidy up', durationMin: 10),
  RoutineStepData(title: 'Shower', durationMin: 15),
  RoutineStepData(title: 'Brush your teeth', durationMin: 5),
  RoutineStepData(title: 'Read', durationMin: 25),
];

const List<RoutineStepData> starterMorningSteps = [
  RoutineStepData(title: 'Glass of water', durationMin: 5),
  RoutineStepData(title: 'Shower', durationMin: 15),
  RoutineStepData(title: 'Brush your teeth', durationMin: 5),
  RoutineStepData(title: 'Get dressed', durationMin: 10),
  RoutineStepData(title: 'Breakfast', durationMin: 20),
];

/// Suggesties in het toevoegscherm.
const List<RoutineStepData> eveningStepLibrary = [
  RoutineStepData(title: 'Put your phone away', durationMin: 5),
  RoutineStepData(title: 'Screens off', durationMin: 5),
  RoutineStepData(title: 'Tidy up', durationMin: 10),
  RoutineStepData(title: 'Shower', durationMin: 15),
  RoutineStepData(title: 'Brush your teeth', durationMin: 5),
  RoutineStepData(title: 'Read', durationMin: 25),
  RoutineStepData(title: 'Sit quietly', durationMin: 10),
  RoutineStepData(title: 'Stretch', durationMin: 10),
  RoutineStepData(title: 'Write down your day', durationMin: 10),
  RoutineStepData(title: 'Tea', durationMin: 10),
  RoutineStepData(title: 'Prepare for tomorrow', durationMin: 10),
];

const List<RoutineStepData> morningStepLibrary = [
  RoutineStepData(title: 'Glass of water', durationMin: 5),
  RoutineStepData(title: 'Shower', durationMin: 15),
  RoutineStepData(title: 'Brush your teeth', durationMin: 5),
  RoutineStepData(title: 'Get dressed', durationMin: 10),
  RoutineStepData(title: 'Breakfast', durationMin: 20),
  RoutineStepData(title: 'Coffee or tea', durationMin: 10),
  RoutineStepData(title: 'Make the bed', durationMin: 5),
  RoutineStepData(title: 'Go outside', durationMin: 15),
  RoutineStepData(title: 'Move or stretch', durationMin: 10),
  RoutineStepData(title: 'Sit quietly', durationMin: 10),
  RoutineStepData(title: 'Read', durationMin: 15),
  RoutineStepData(title: 'Write', durationMin: 10),
];
