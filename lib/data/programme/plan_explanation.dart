import '../../l10n/app_localizations.dart';
import '../../l10n/plan_labels.dart';
import '../database/enums.dart';
import 'content_catalog.dart';
import 'plan_input.dart';

/// Eén reden in "Why we chose this for you": waar het over gaat en wat het
/// met het plan doet.
class PlanReason {
  const PlanReason(this.label, this.text);

  final String label;
  final String text;
}

/// Legt in gewone woorden uit hoe de antwoorden uit de onboarding het plan
/// hebben gevormd. Noemt geen technische sleutels en belooft niets over slaap.
class PlanExplanation {
  const PlanExplanation(this.reasons);

  final List<PlanReason> reasons;

  /// Staat onder elke uitleg. Het plan is een voorstel, geen behandeling.
  /// Engels; gebruik [disclaimerFor] voor de gekozen taal.
  static const disclaimer =
      'This plan is a suggestion based on your answers, not medical advice. '
      'It can’t promise better sleep, and you can change it whenever you like.';

  static String disclaimerFor(AppLocalizations? l10n) =>
      (l10n ?? englishL10n()).planDisclaimer;

  /// De naam van een activiteit zoals op het activiteitenscherm, op basis van
  /// de zin die het plan voor die activiteit gebruikt ([PlanInput.activity]).
  static String? activityLabel(AppLocalizations l10n, String? phrase) {
    if (phrase == PlanPhrases.forActivity(PreferredActivity.quietSitting, l10n).activity) {
      return l10n.activityQuietTitle;
    }
    if (phrase == PlanPhrases.forActivity(PreferredActivity.reading, l10n).activity) {
      return l10n.activityReadingTitle;
    }
    if (phrase == PlanPhrases.forActivity(PreferredActivity.breathing, l10n).activity) {
      return l10n.activityBreathingTitle;
    }
    return null;
  }

  static String _goalEffect(AppLocalizations l10n, String goal) => switch (goal) {
        'phone' => l10n.goalEffectPhone,
        'routine' => l10n.goalEffectRoutine,
        'social' => l10n.goalEffectSocial,
        _ => l10n.goalEffectDefault,
      };

  /// Begin van het uitwindvenster (`bedtime_minutes`) naar leesbare tekst.
  static String? windDownText(int? minutes, [AppLocalizations? l10n]) {
    final t = l10n ?? englishL10n();
    return switch (minutes) {
      1200 => t.windDownEarly,
      1320 => t.windDownMid,
      0 => t.windDownLate,
      _ => null,
    };
  }

  factory PlanExplanation.build(
    PlanInput input,
    ContentCatalog catalog, {
    int? windDownStartMinutes,
    AppLocalizations? l10n,
  }) {
    final t = l10n ?? englishL10n();
    final reasons = <PlanReason>[
      PlanReason(t.reasonYourGoal, _goalEffect(t, input.goal)),
    ];

    final tip = catalog.obstacleActions[input.obstacle];
    if (tip != null) {
      reasons.add(PlanReason(t.reasonObstacle, t.reasonObstacleText(tip)));
    }

    final window = windDownText(windDownStartMinutes, t);
    if (input.rhythm != 'regular') {
      reasons.add(PlanReason(t.reasonRhythm, t.reasonRhythmVariable));
    } else if (window != null) {
      reasons.add(PlanReason(t.reasonRhythm, t.reasonRhythmWindow(window)));
    }

    if (input.anchor != null) {
      reasons.add(PlanReason(t.reasonAnchor, t.reasonAnchorText(input.anchor!)));
    }

    final activity = activityLabel(t, input.activity);
    if (activity != null) {
      reasons.add(PlanReason(t.reasonEnjoy, t.reasonEnjoyText(activity)));
    }

    reasons.add(PlanReason(
      t.reasonStepSize,
      input.smaller ? t.reasonStepSizeSmaller : t.reasonStepSizeStandard,
    ));

    if (input.restnest || input.card) {
      reasons.add(PlanReason(
        t.reasonProducts,
        [
          if (input.restnest) t.productRestnest,
          if (input.card) t.productCard,
        ].join(' '),
      ));
    }

    return PlanExplanation(reasons);
  }
}
