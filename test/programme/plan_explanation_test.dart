import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/programme/content_catalog.dart';
import 'package:rest4more/data/programme/plan_explanation.dart';
import 'package:rest4more/data/programme/plan_input.dart';

ContentCatalog loadCatalog() => ContentCatalog.parse(
    File('assets/programme/programme_content.json').readAsStringSync());

void main() {
  final catalog = loadCatalog();

  List<String> labels(PlanExplanation e) => [for (final r in e.reasons) r.label];
  String allText(PlanExplanation e) =>
      [for (final r in e.reasons) '${r.label} ${r.text}'].join('\n');

  test('de uitleg verbindt het plan met de antwoorden', () {
    final explanation = PlanExplanation.build(
      PlanInput(
        goal: 'phone',
        obstacle: 'thoughts',
        activity: PlanPhrases.forActivity(PreferredActivity.reading).activity,
      ),
      catalog,
      windDownStartMinutes: 22 * 60,
    );
    expect(labels(explanation), [
      'Your goal',
      'What gets in the way',
      'Your rhythm',
      'What you enjoy',
      'Step size',
    ]);
    final text = allText(explanation);
    expect(text, contains(catalog.obstacleActions['thoughts']));
    expect(text, contains('between 10 PM and midnight'));
    expect(text, contains('Paper reading'));
  });

  test('geen technische sleutels in de uitleg', () {
    for (final goal in catalog.goals.keys) {
      for (final obstacle in catalog.obstacleActions.keys) {
        final text = allText(PlanExplanation.build(
            PlanInput(goal: goal, obstacle: obstacle), catalog));
        expect(text, isNot(contains('_')), reason: '$goal $obstacle');
        expect(text, isNot(contains('{')), reason: '$goal $obstacle');
      }
    }
  });

  test('een wisselend ritme koppelt aan een moment, niet aan een uur', () {
    final explanation = PlanExplanation.build(
      const PlanInput(goal: 'routine', obstacle: 'planning', rhythm: 'shifts'),
      catalog,
      windDownStartMinutes: 20 * 60,
    );
    final rhythm = explanation.reasons.firstWhere((r) => r.label == 'Your rhythm');
    expect(rhythm.text, contains('instead of a fixed hour'));
  });

  test('de kleine stap wordt niet als minder gebracht', () {
    final explanation = PlanExplanation.build(
        const PlanInput(goal: 'social', obstacle: 'scrolling', smaller: true),
        catalog);
    final size = explanation.reasons.firstWhere((r) => r.label == 'Step size');
    expect(size.text, contains('count just as much'));
  });

  test('producten alleen als de gebruiker ze heeft', () {
    final without = PlanExplanation.build(
        const PlanInput(goal: 'phone', obstacle: 'alarm'), catalog);
    final withProducts = PlanExplanation.build(
        const PlanInput(
            goal: 'phone', obstacle: 'alarm', restnest: true, card: true),
        catalog);
    expect(labels(without), isNot(contains('Your products')));
    expect(allText(withProducts), contains('RestNest'));
    expect(allText(withProducts), contains('card'));
  });

  test('twee verschillende profielen geven een andere uitleg', () {
    final a = PlanExplanation.build(
        const PlanInput(goal: 'phone', obstacle: 'scrolling'), catalog);
    final b = PlanExplanation.build(
        const PlanInput(goal: 'routine', obstacle: 'availability'), catalog);
    expect(allText(a), isNot(allText(b)));
  });

  test('geen medische beloftes', () {
    const disclaimer = PlanExplanation.disclaimer;
    expect(disclaimer, contains('not medical advice'));
    expect(disclaimer, contains('can’t promise'));
    final text = allText(PlanExplanation.build(
        const PlanInput(goal: 'routine', obstacle: 'no_routine'), catalog));
    for (final word in ['guarantee', 'cure', 'treatment', 'diagnos']) {
      expect(text.toLowerCase(), isNot(contains(word)));
    }
  });
}
