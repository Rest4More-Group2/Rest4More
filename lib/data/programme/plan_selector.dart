import '../../l10n/app_localizations.dart';
import '../../l10n/plan_labels.dart';
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
List<Map<String, Object?>> selectPlan(
  PlanInput input,
  ContentCatalog catalog, {
  AppLocalizations? l10n,
}) {
  final t = l10n ?? englishL10n();
  if (!catalog.goals.containsKey(input.goal)) {
    throw UnknownPlanChoice('doel ${input.goal}');
  }
  final obstacleAction = catalog.obstacleActions[input.obstacle];
  if (obstacleAction == null) {
    throw UnknownPlanChoice('belemmering ${input.obstacle}');
  }

  final values = {
    'anchor': input.anchor ?? t.planDefaultAnchor,
    'activity': input.activity ?? PlanPhrases.forActivity(null, t).activity,
    'activity_material':
        input.activityMaterial ?? PlanPhrases.forActivity(null, t).material,
  };
  String fill(String text) => text.replaceAllMapped(
        RegExp(r'\{(\w+)\}'),
        (match) => values[match.group(1)] ?? match.group(0)!,
      );

  final goalName = catalog.goals[input.goal]!.toLowerCase();
  // De Engelse tekst moet gelijk blijven aan de referentie van de
  // opdrachtgevers, die de sleutel van de belemmering noemt. Andere talen
  // krijgen een leesbare omschrijving.
  final obstacleText = t.localeName == 'en'
      ? input.obstacle
      : obstaclePhrase(t, input.obstacle);
  return [
    for (final row in catalog.daysFor(input.goal))
      {
        ...row,
        'action': fill(row['action'] as String),
        'smaller_action': fill(row['smaller_action'] as String),
        'obstacle_action': obstacleAction,
        'context_instruction':
            input.restnest ? t.planContextRestnest : t.planContextNoRestnest,
        'card_instruction': input.card ? t.planCardOn : t.planCardOff,
        'why_this': t.planWhyThis(goalName, obstacleText),
        'timing_note':
            input.rhythm == 'regular' ? t.planTimingRegular : t.planTimingOther,
      },
  ];
}
