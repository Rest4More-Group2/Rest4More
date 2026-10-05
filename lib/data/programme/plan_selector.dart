import 'content_catalog.dart';
import 'plan_input.dart';

/// Het gekozen doel of de belemmering staat niet in de inhoud.
class UnknownPlanChoice implements Exception {
  const UnknownPlanChoice(this.message);

  final String message;

  @override
  String toString() => 'UnknownPlanChoice: $message';
}

/// Maakt van de invoer de veertien uitgewerkte dagen. Een pure functie: zelfde
/// invoer en inhoud geven altijd hetzelfde plan.
///
/// Volgt de referentie `select_plan.py` van de opdrachtgevers, met als
/// verschil dat ontbrekende antwoorden een neutrale zin krijgen in plaats van
/// een fout.
List<Map<String, Object?>> selectPlan(PlanInput input, ContentCatalog catalog) {
  if (!catalog.goals.containsKey(input.goal)) {
    throw UnknownPlanChoice('doel ${input.goal}');
  }
  final obstacleAction = catalog.obstacleActions[input.obstacle];
  if (obstacleAction == null) {
    throw UnknownPlanChoice('belemmering ${input.obstacle}');
  }

  final values = {
    'anchor': input.anchor ?? PlanPhrases.defaultAnchor,
    'activity': input.activity ?? PlanPhrases.forActivity(null).activity,
    'activity_material':
        input.activityMaterial ?? PlanPhrases.forActivity(null).material,
  };
  String fill(String text) => text.replaceAllMapped(
        RegExp(r'\{(\w+)\}'),
        (match) => values[match.group(1)] ?? match.group(0)!,
      );

  final goalName = catalog.goals[input.goal]!.toLowerCase();
  return [
    for (final row in catalog.daysFor(input.goal))
      {
        ...row,
        'action': fill(row['action'] as String),
        'smaller_action': fill(row['smaller_action'] as String),
        'obstacle_action': obstacleAction,
        'context_instruction': input.restnest
            ? 'Use your RestNest as the fixed phone location.'
            : 'Choose a fixed place for your phone; a RestNest is not required.',
        'card_instruction': input.card
            ? 'Use your paired card when card functionality is available on this device.'
            : 'Use manual start; physical card release is unavailable without a card.',
        'why_this':
            'This fits your goal to $goalName and your selected obstacle: ${input.obstacle}.',
        'timing_note': input.rhythm == 'regular'
            ? 'Use your selected daily time.'
            : 'Check whether your selected time fits today; otherwise use your activity anchor.',
      },
  ];
}
