/// Aantal dagen in het programma.
const planLength = 14;

/// Op welke dag het plan begint (lokale kalenderdatum).
///
/// Zonder herinnering begint het vandaag. Met een herinnering vandaag als die
/// nog meer dan een uur weg is, anders morgen, zodat de eerste melding niet
/// meteen of al voorbij is.
DateTime planStartDate({required DateTime now, int? reminderMinutes}) {
  final today = DateTime(now.year, now.month, now.day);
  if (reminderMinutes == null) return today;
  final nowMinutes = now.hour * 60 + now.minute;
  return reminderMinutes - nowMinutes > 60
      ? today
      : DateTime(now.year, now.month, now.day + 1);
}

/// De datum van elke dag, beginnend bij [start]. Telt kalenderdagen, dus een
/// zomer- of wintertijdwisseling verschuift niets.
List<DateTime> planDates(DateTime start) => [
      for (var i = 0; i < planLength; i++)
        DateTime(start.year, start.month, start.day + i),
    ];
