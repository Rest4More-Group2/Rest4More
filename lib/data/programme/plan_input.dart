import '../database/app_database.dart';
import '../database/enums.dart';

/// Wat het plan nodig heeft, met dezelfde sleutels als de inhoud van het
/// programma (`programme_content.json`).
class PlanInput {
  const PlanInput({
    required this.goal,
    required this.obstacle,
    this.rhythm = 'regular',
    this.anchor,
    this.activity,
    this.activityMaterial,
    this.restnest = false,
    this.card = false,
    this.smaller = false,
    this.reminderMinutes,
  });

  /// `phone`, `routine` of `social`.
  final String goal;

  /// `scrolling`, `availability`, `thoughts`, `planning`, `alarm` of `no_routine`.
  final String obstacle;

  /// `regular`, `variable` of `shifts`.
  final String rhythm;

  /// Vrije tekst, bijvoorbeeld "brushing my teeth". Null geeft een neutrale zin.
  final String? anchor;
  final String? activity;
  final String? activityMaterial;
  final bool restnest;
  final bool card;

  /// De gebruiker koos de kleine stap als standaard.
  final bool smaller;

  /// Tijd van de herinnering in minuten sinds middernacht, of null zonder.
  final int? reminderMinutes;

  /// Leest de invoer uit het profiel. Ontbrekende antwoorden krijgen een
  /// rustige standaard. Geeft null als er geen doel is, want zonder doel is er
  /// geen plan.
  static PlanInput? fromProfile(Profile profile) {
    final goal = profile.primaryGoal;
    if (goal == null || goal == PrimaryGoal.unknown) return null;

    final obstacle = profile.obstacle;
    final activity = profile.preferredActivity;
    final phrases = PlanPhrases.forActivity(activity);
    return PlanInput(
      goal: goal.id,
      obstacle: obstacle == null || obstacle == Obstacle.unknown
          ? Obstacle.noRoutine.id
          : obstacle.id,
      rhythm: switch (profile.rhythm) {
        Rhythm.variable => 'variable',
        Rhythm.shifts => 'shifts',
        _ => 'regular',
      },
      anchor: _blankToNull(profile.anchorText),
      activity: phrases.activity,
      activityMaterial: _blankToNull(profile.activityMaterial) ?? phrases.material,
      restnest: profile.ownsRestnest,
      card: profile.ownsCard,
      smaller: profile.stepSize == StepSize.short,
      reminderMinutes:
          profile.notifyProgramme ? profile.notifyTimeMinutes : null,
    );
  }

  static String? _blankToNull(String? text) {
    final trimmed = text?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Map<String, Object?> toJson() => {
        'goal': goal,
        'obstacle': obstacle,
        'rhythm': rhythm,
        'anchor': anchor,
        'activity': activity,
        'activity_material': activityMaterial,
        'restnest': restnest,
        'card': card,
        'smaller': smaller,
        'reminder_minutes': reminderMinutes,
      };
}

/// Zinnen voor de gekozen activiteit. De inhoud van het programma gebruikt ze
/// midden in een zin ("Begin {activity}"), dus het zijn werkwoordsgroepen.
class PlanPhrases {
  const PlanPhrases(this.activity, this.material);

  final String activity;
  final String material;

  static PlanPhrases forActivity(PreferredActivity? activity) =>
      switch (activity) {
        PreferredActivity.reading =>
          const PlanPhrases('reading a few pages', 'your book'),
        PreferredActivity.quietSitting => const PlanPhrases(
            'sitting quietly for a few minutes', 'a comfortable place to sit'),
        PreferredActivity.breathing => const PlanPhrases(
            'a few minutes of slow breathing', 'a quiet corner'),
        PreferredActivity.preparation => const PlanPhrases(
            'preparing for tomorrow', 'what you need for tomorrow'),
        _ => const PlanPhrases(
            'a calm activity of your choice', 'what you need for it'),
      };

  /// Als er geen anker is gekozen.
  static const defaultAnchor = 'your usual evening routine';
}
