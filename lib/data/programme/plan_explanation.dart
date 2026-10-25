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
  static const disclaimer =
      'This plan is a suggestion based on your answers, not medical advice. '
      'It can’t promise better sleep, and you can change it whenever you like.';

  /// Zoals op het doelscherm.
  static const goalLabels = {
    'phone': 'Put the phone away earlier',
    'routine': 'Build a routine',
    'social': 'Use less social media',
  };

  /// Zoals op het belemmeringenscherm.
  static const obstacleLabels = {
    'scrolling': 'Scrolling',
    'availability': 'Availability',
    'thoughts': 'Restless thoughts',
    'planning': 'Planning',
    'alarm': 'Phone as alarm',
    'no_routine': 'No routine',
  };

  /// Zoals op het activiteitenscherm, op [PlanPhrases.activity].
  static final activityLabels = {
    PlanPhrases.forActivity(PreferredActivity.quietSitting).activity:
        'Quiet moments',
    PlanPhrases.forActivity(PreferredActivity.reading).activity:
        'Paper reading',
    PlanPhrases.forActivity(PreferredActivity.breathing).activity:
        'Evening breathing routines',
  };

  static const _goalEffect = {
    'phone':
        'Each day has one step that puts a little more distance between you '
            'and your phone in the evening.',
    'routine':
        'Each day adds one small, repeatable part to your evening, so it '
            'slowly becomes a routine.',
    'social':
        'Each day helps you notice one automatic check and choose what to do '
            'instead.',
  };

  /// Begin van het uitwindvenster (`bedtime_minutes`) naar leesbare tekst.
  static String? windDownText(int? minutes) => switch (minutes) {
        1200 => 'between 8 and 10 PM',
        1320 => 'between 10 PM and midnight',
        0 => 'after midnight',
        _ => null,
      };

  factory PlanExplanation.build(
    PlanInput input,
    ContentCatalog catalog, {
    int? windDownStartMinutes,
  }) {
    final reasons = <PlanReason>[
      PlanReason('Your goal',
          _goalEffect[input.goal] ?? 'Each day has one step towards your goal.'),
    ];

    final tip = catalog.obstacleActions[input.obstacle];
    if (tip != null) {
      reasons.add(PlanReason(
        'What gets in the way',
        'You told us about this, so every step comes with a tip for it: $tip',
      ));
    }

    final window = windDownText(windDownStartMinutes);
    if (input.rhythm != 'regular') {
      reasons.add(const PlanReason(
        'Your rhythm',
        'Your days are not always the same, so each step is linked to a '
            'moment in your day instead of a fixed hour.',
      ));
    } else if (window != null) {
      reasons.add(PlanReason(
        'Your rhythm',
        'You usually wind down $window, so the steps are meant for that part '
            'of your evening.',
      ));
    }

    if (input.anchor != null) {
      reasons.add(PlanReason(
        'Your fixed moment',
        'Steps start after something you already do: ${input.anchor}.',
      ));
    }

    final activity = activityLabels[input.activity];
    if (activity != null) {
      reasons.add(PlanReason(
        'What you enjoy',
        'You picked “$activity”, so that is the calm alternative in your '
            'steps.',
      ));
    }

    reasons.add(input.smaller
        ? const PlanReason(
            'Step size',
            'You chose smaller steps. They count just as much, and you can '
                'make them bigger later if you want to.',
          )
        : const PlanReason(
            'Step size',
            'If a step feels too big, you can switch to a smaller version at '
                'any time.',
          ));

    if (input.restnest || input.card) {
      reasons.add(PlanReason(
        'Your products',
        [
          if (input.restnest) 'Your RestNest is used as the place for your phone.',
          if (input.card) 'You can start and end a moment with your card.',
        ].join(' '),
      ));
    }

    return PlanExplanation(reasons);
  }
}
