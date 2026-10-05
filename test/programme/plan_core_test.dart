import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/programme/content_catalog.dart';
import 'package:rest4more/data/programme/plan_input.dart';
import 'package:rest4more/data/programme/plan_scheduler.dart';
import 'package:rest4more/data/programme/plan_selector.dart';

ContentCatalog loadCatalog() => ContentCatalog.parse(
    File('assets/programme/programme_content.json').readAsStringSync());

PlanInput fromSample(Map<String, dynamic> p) => PlanInput(
      goal: p['goal'] as String,
      obstacle: p['obstacle'] as String,
      rhythm: p['rhythm'] as String,
      anchor: p['anchor'] as String?,
      activity: p['activity'] as String?,
      activityMaterial: p['activity_material'] as String?,
      restnest: p['restnest'] as bool,
      card: p['card'] as bool,
    );

void main() {
  final catalog = loadCatalog();

  group('referentie van de opdrachtgevers', () {
    final profiles = (jsonDecode(File('test/fixtures/programme/sample_profiles.json')
            .readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();
    final plans = (jsonDecode(File('test/fixtures/programme/sample_plans.json')
            .readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();

    test('er zijn drie voorbeeldprofielen', () {
      expect(profiles, hasLength(3));
      expect(plans, hasLength(3));
    });

    for (var i = 0; i < 3; i++) {
      test('profiel ${profiles[i]['id']} geeft precies hetzelfde plan', () {
        final mine = selectPlan(fromSample(profiles[i]), catalog);
        final reference = (plans[i]['days'] as List).cast<Map<String, dynamic>>();
        expect(mine, hasLength(14));
        expect(plans[i]['version'], catalog.version);
        for (var d = 0; d < 14; d++) {
          expect(mine[d], reference[d], reason: 'dag ${d + 1}');
        }
      });
    }
  });

  group('plan zonder fouten', () {
    test('elk doel met elke belemmering geeft 14 dagen zonder open plekken', () {
      for (final goal in catalog.goals.keys) {
        for (final obstacle in catalog.obstacleActions.keys) {
          final plan = selectPlan(PlanInput(goal: goal, obstacle: obstacle), catalog);
          expect(plan, hasLength(14), reason: '$goal/$obstacle');
          expect(plan.map((d) => d['day']), [for (var i = 1; i <= 14; i++) i]);
          for (final day in plan) {
            for (final key in ['action', 'smaller_action', 'title']) {
              expect(day[key] as String, isNot(contains('{')),
                  reason: '$goal/$obstacle dag ${day['day']} $key');
            }
          }
        }
      }
    });

    test('ontbrekende antwoorden krijgen een neutrale zin', () {
      final plan = selectPlan(const PlanInput(goal: 'routine', obstacle: 'planning'), catalog);
      final day2 = plan[1]['action'] as String;
      expect(day2, contains(PlanPhrases.defaultAnchor));
      final day4 = plan[3]['action'] as String;
      expect(day4, contains('a calm activity of your choice'));
    });

    test('onbekend doel of belemmering geeft een duidelijke fout', () {
      expect(() => selectPlan(const PlanInput(goal: 'x', obstacle: 'scrolling'), catalog),
          throwsA(isA<UnknownPlanChoice>()));
      expect(() => selectPlan(const PlanInput(goal: 'phone', obstacle: 'x'), catalog),
          throwsA(isA<UnknownPlanChoice>()));
    });

    test('dezelfde invoer geeft hetzelfde plan', () {
      const input = PlanInput(goal: 'social', obstacle: 'alarm', activity: 'x');
      expect(selectPlan(input, catalog), selectPlan(input, catalog));
    });

    test('de rest-van-het-ritme-zin hangt van het ritme af', () {
      final regular = selectPlan(const PlanInput(goal: 'phone', obstacle: 'alarm'), catalog);
      final shifts = selectPlan(
          const PlanInput(goal: 'phone', obstacle: 'alarm', rhythm: 'shifts'), catalog);
      expect(regular.first['timing_note'], 'Use your selected daily time.');
      expect(shifts.first['timing_note'], isNot(regular.first['timing_note']));
    });
  });

  group('planning', () {
    DateTime at(int h, int m) => DateTime(2026, 3, 2, h, m);

    test('zonder herinnering begint het vandaag', () {
      expect(planStartDate(now: at(23, 30)), DateTime(2026, 3, 2));
    });

    test('herinnering meer dan een uur weg: vandaag', () {
      expect(planStartDate(now: at(20, 0), reminderMinutes: 22 * 60), DateTime(2026, 3, 2));
    });

    test('herinnering binnen een uur of voorbij: morgen', () {
      expect(planStartDate(now: at(21, 0), reminderMinutes: 22 * 60), DateTime(2026, 3, 3));
      expect(planStartDate(now: at(21, 59), reminderMinutes: 22 * 60), DateTime(2026, 3, 3));
      expect(planStartDate(now: at(23, 0), reminderMinutes: 22 * 60), DateTime(2026, 3, 3));
    });

    test('exact een uur weg is nog vandaag niet, een minuut meer wel', () {
      expect(planStartDate(now: at(21, 0), reminderMinutes: 22 * 60), DateTime(2026, 3, 3));
      expect(planStartDate(now: at(20, 59), reminderMinutes: 22 * 60), DateTime(2026, 3, 2));
    });

    test('veertien opeenvolgende kalenderdagen, ook over maand- en tijdwisselingen', () {
      final dates = planDates(DateTime(2026, 3, 25));
      expect(dates, hasLength(14));
      expect(dates.first, DateTime(2026, 3, 25));
      expect(dates.last, DateTime(2026, 4, 7));
      for (var i = 1; i < 14; i++) {
        expect(dates[i].day != dates[i - 1].day, isTrue);
        expect(dates[i].hour, 0, reason: 'altijd middernacht lokaal');
      }
    });
  });
}
