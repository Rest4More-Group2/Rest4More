import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Engelse teksten voor code die geen taal kent (en voor de tests).
AppLocalizations englishL10n() => lookupAppLocalizations(const Locale('en'));

/// Vertaalde namen voor de antwoorden uit de intake, op basis van de id's die
/// `PlanExplanation` gebruikt.
String goalLabel(AppLocalizations l10n, String id) => switch (id) {
      'phone' => l10n.goalPhoneTitle,
      'routine' => l10n.goalRoutineTitle,
      _ => l10n.goalSocialTitle,
    };

String obstacleLabel(AppLocalizations l10n, String id) => switch (id) {
      'scrolling' => l10n.obstacleScrolling,
      'availability' => l10n.obstacleAvailability,
      'thoughts' => l10n.obstacleThoughts,
      'planning' => l10n.obstaclePlanning,
      'alarm' => l10n.obstacleAlarm,
      _ => l10n.obstacleNoRoutine,
    };

/// Korte omschrijving van een belemmering, midden in een zin.
String obstaclePhrase(AppLocalizations l10n, String id) => switch (id) {
      'scrolling' => l10n.obstaclePhraseScrolling,
      'availability' => l10n.obstaclePhraseAvailability,
      'thoughts' => l10n.obstaclePhraseThoughts,
      'planning' => l10n.obstaclePhrasePlanning,
      'alarm' => l10n.obstaclePhraseAlarm,
      'no_routine' => l10n.obstaclePhraseNoRoutine,
      _ => id,
    };
