import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:rest4more/data/moments/moment_profiles.dart' show MomentKind;
import 'package:rest4more/data/moments/moment_schedule.dart';

import 'app_localizations.dart';

/// Naam van een `DateTime.weekday` (1 tot en met 7) in de gekozen taal.
String localizedWeekday(BuildContext context, int weekday) {
  // 1 januari 2024 was een maandag.
  final date = DateTime(2024, 1, weekday);
  final name = DateFormat.EEEE(Localizations.localeOf(context).toString())
      .format(date);
  return toBeginningOfSentenceCase(name);
}

/// Zoals `formatDuration`, maar met de eenheden van de gekozen taal.
String localizedDuration(AppLocalizations l10n, int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return l10n.durationMinutes(m);
  if (m == 0) return l10n.durationHours(h);
  return l10n.durationHoursMinutes(h, m.toString().padLeft(2, '0'));
}

String eveningEndLabel(AppLocalizations l10n, EveningEnd end) => switch (end) {
      EveningEnd.atBedtime => l10n.eveningEndAtBedtime,
      EveningEnd.atNextScan => l10n.eveningEndAtNextScan,
    };

/// Naam van een moment in de gekozen taal. `MomentKind.profileName` blijft de
/// sleutel van het blokkeerprofiel en wordt dus niet vertaald.
String momentKindName(AppLocalizations l10n, MomentKind kind) => switch (kind) {
      MomentKind.focus => l10n.momentFocusTitle,
      MomentKind.reading => l10n.momentReadingTitle,
      MomentKind.evening => l10n.momentEveningTitle,
      MomentKind.morning => l10n.momentMorningTitle,
      MomentKind.tag => l10n.momentTagTitle,
    };
