import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/intake/intake_service.dart';
import 'package:rest4more/data/programme/plan_service.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/providers/database_providers.dart';
import 'package:rest4more/providers/locale_providers.dart';
import 'package:rest4more/providers/plan_providers.dart';
import 'package:rest4more/providers/repository_providers.dart';
import 'package:rest4more/data/programme/content_catalog.dart';
import 'package:rest4more/data/programme/plan_explanation.dart';
import 'package:rest4more/data/programme/plan_input.dart';
import 'package:rest4more/data/programme/plan_preview.dart';
import 'package:rest4more/data/programme/plan_selector.dart';
import 'package:rest4more/data/programme/today_plan.dart';
import 'package:rest4more/l10n/app_localizations.dart';

import '../data/test_support.dart';

void main() {
  final nl = lookupAppLocalizations(const Locale('nl'));
  final en = ContentCatalog.parse(
      File('assets/programme/programme_content.json').readAsStringSync());
  final catalog = ContentCatalog.parse(
      File('assets/programme/programme_content_nl.json').readAsStringSync());

  test('de Nederlandse inhoud heeft dezelfde dagen als de Engelse', () {
    expect(catalog.version, '1.0-nl');
    expect(catalog.goals.keys, en.goals.keys);
    expect(catalog.obstacleActions.keys, en.obstacleActions.keys);
    for (final goal in en.goals.keys) {
      final a = en.daysFor(goal), b = catalog.daysFor(goal);
      expect(b.length, a.length);
      for (var i = 0; i < a.length; i++) {
        expect(b[i]['day'], a[i]['day']);
        // Dezelfde invulvelden, dus niets raakt kwijt of blijft staan.
        final tokens = RegExp(r'\{\w+\}');
        for (final field in ['action', 'smaller_action']) {
          expect(
            tokens.allMatches(b[i][field] as String).map((m) => m[0]).toList(),
            tokens.allMatches(a[i][field] as String).map((m) => m[0]).toList(),
            reason: '${goal} dag ${a[i]['day']} $field',
          );
        }
      }
    }
  });

  test('een Nederlands plan bevat geen Engelse restanten of lege velden', () {
    const input = PlanInput(
        goal: 'phone', obstacle: 'scrolling', activity: null, restnest: true);
    final days = selectPlan(input, catalog, l10n: nl);
    expect(days, hasLength(14));
    for (final d in days) {
      expect(d['action'], isNot(contains('{')));
      expect(d['why_this'], contains('scrollen'));
    }
    expect(days[1]['action'], contains('je gebruikelijke avondroutine'));
    expect(days[0]['context_instruction'], startsWith('Gebruik je RestNest'));
  });

  test('uitleg, voorbeeldplan en begroeting volgen de taal', () {
    const input = PlanInput(goal: 'routine', obstacle: 'alarm', smaller: true);
    final explanation = PlanExplanation.build(input, catalog, l10n: nl);
    expect(explanation.reasons.first.label, 'Jouw doel');
    expect(PlanExplanation.disclaimerFor(nl), contains('geen medisch advies'));
    final preview = PlanPreview.build(input, catalog, l10n: nl);
    expect(preview.reason, contains('je telefoon als wekker gebruiken'));
    expect(greetingFor(DateTime(2026, 3, 2, 8), nl), 'Goedemorgen');
  });

  test('een Engels plan wordt Nederlands na het wisselen van taal', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final intake = IntakeService(ProfileRepository(db));
    await intake.saveGoal(0);
    await intake.saveObstacles([0]);
    await intake.saveRhythm(1);
    await intake.saveActivities([1]);
    await intake.savePlanSeen();
    await intake.complete(reminderEnabled: false);
    // Het plan wordt in het Engels gemaakt.
    await PlanService(db, () async => en).ensurePlan();

    ProviderContainer containerFor(AppLocalizations l10n) {
      final c = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        l10nProvider.overrideWithValue(l10n),
        contentCatalogLoaderProvider.overrideWithValue(
            () async => l10n.localeName == 'nl' ? catalog : en),
      ]);
      addTearDown(c.dispose);
      // Riverpod 3 pauzeert streamproviders zonder luisteraar.
      c.listen(activeEnrollmentProvider, (_, _) {});
      c.listen(programmeDaysProvider, (_, _) {});
      c.listen(localizedPlanDaysProvider, (_, _) {});
      return c;
    }

    final english = containerFor(lookupAppLocalizations(const Locale('en')));
    await english.read(activeEnrollmentProvider.future);
    await english.read(programmeDaysProvider.future);
    await english.read(localizedPlanDaysProvider.future);
    final before = english.read(todayPlanProvider).value!;
    expect(before.title, 'Your starting point');

    final dutch = containerFor(nl);
    await dutch.read(activeEnrollmentProvider.future);
    await dutch.read(programmeDaysProvider.future);
    await dutch.read(localizedPlanDaysProvider.future);
    final after = dutch.read(todayPlanProvider).value!;
    expect(after.day, before.day);
    expect(after.title, 'Je startpunt');
    expect(after.action, isNot(equals(before.action)));

    // Het bewaarde plan blijft zoals de gebruiker het kreeg.
    final stored = await db.select(db.programmeDays).get();
    expect(stored.every((d) => d.snapshot['content_version'] == '1.0-en'),
        isTrue);
  });
}
