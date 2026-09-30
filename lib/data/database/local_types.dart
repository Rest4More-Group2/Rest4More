/// Bitmasker voor weekdagen. Maandag is 1, dinsdag 2, woensdag 4, enzovoort
/// tot en met zondag 64.
class WeekdayMask {
  const WeekdayMask(this.value);

  /// Bouwt een masker uit `DateTime.weekday`-waarden (1 tot en met 7).
  /// Waarden buiten dat bereik worden genegeerd.
  factory WeekdayMask.fromWeekdays(Set<int> weekdays) {
    var mask = 0;
    for (final day in weekdays) {
      if (day >= DateTime.monday && day <= DateTime.sunday) {
        mask |= 1 << (day - 1);
      }
    }
    return WeekdayMask(mask);
  }

  static const none = WeekdayMask(0);
  static const everyDay = WeekdayMask(127);

  final int value;

  /// Zet het masker terug om naar `DateTime.weekday`-waarden.
  Set<int> toWeekdays() => {
        for (var day = DateTime.monday; day <= DateTime.sunday; day++)
          if (value & (1 << (day - 1)) != 0) day,
      };

  bool includes(int weekday) => toWeekdays().contains(weekday);

  @override
  bool operator ==(Object other) =>
      other is WeekdayMask && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Lokale kalenderdatum als tekst in de vorm `YYYY-MM-DD`. Geen tijdzone,
/// zodat een datum niet verschuift als de gebruiker reist.
class LocalDate {
  const LocalDate._();

  static String format(DateTime dateTime) {
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Geeft null bij onleesbare tekst.
  static DateTime? parse(String? text) {
    if (text == null) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    if (date.month != month || date.day != day) return null;
    return date;
  }
}
