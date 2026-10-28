import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/converters.dart';
import 'package:rest4more/data/repositories/moment_plan_repository.dart';
import 'package:rest4more/data/moments/moment_plans.dart';
import 'package:rest4more/data/moments/moment_schedule.dart';
import 'package:rest4more/providers/database_providers.dart';
import 'package:rest4more/providers/repository_providers.dart';
import 'package:rest4more/screens/saved_moment_pages.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/test_support.dart';

class _FailingStore extends PrefsMomentPlanStore {
  @override
  Future<void> saveEvening(EveningPlan plan) async => throw StateError('disk');
}

Future<AppDatabase> _open(WidgetTester tester, Widget page,
    {MomentPlanStore? store}) async {
  tester.view.physicalSize = const Size(1170, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (d) {
    if (d.exceptionAsString().contains('overflowed')) return;
    originalOnError?.call(d);
  };
  addTearDown(() => FlutterError.onError = originalOnError);
  final db = memoryDb();
  addTearDown(db.close);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      if (store != null) momentPlanStoreProvider.overrideWithValue(store),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => page)),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return db;
}

/// Haalt de pagina weg en laat de database-stromen sluiten, anders blijft er
/// een timer hangen.
Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 10));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('een avondplan komt ongewijzigd terug', () async {
    final store = PrefsMomentPlanStore();
    expect(await store.loadEvening(), isNull);
    final plan = EveningPlan.initial().copyWith(
      days: [
        for (final d in EveningPlan.initial().days)
          d.weekday == 5
              ? d.copyWith(bedtimeMinutes: 30, enabled: false)
              : d,
      ],
      steps: const [RoutineStepData(title: 'Read', durationMin: 45)],
      windDownLeadMinutes: 60,
      secondReminderMinutes: 15,
      end: EveningEnd.atNextScan,
    );
    await store.saveEvening(plan);
    final back = (await PrefsMomentPlanStore().loadEvening())!;
    expect(back.days[4].bedtimeMinutes, 30);
    expect(back.days[4].enabled, isFalse);
    expect(back.days[0].enabled, isTrue);
    expect(back.steps, plan.steps);
    expect(back.windDownLeadMinutes, 60);
    expect(back.secondReminderMinutes, 15);
    expect(back.end, EveningEnd.atNextScan);
  });

  test('een ochtendplan komt ongewijzigd terug, ook zonder stappen', () async {
    final store = PrefsMomentPlanStore();
    final plan = MorningPlan.initial().copyWith(
      days: [
        for (final d in MorningPlan.initial().days)
          d.weekday == 1 ? d.copyWith(wakeMinutes: 6 * 60 + 15) : d,
      ],
      steps: const [],
    );
    await store.saveMorning(plan);
    final back = (await store.loadMorning())!;
    expect(back.days.first.wakeMinutes, 6 * 60 + 15);
    expect(back.steps, isEmpty, reason: 'bewust leeg blijft leeg');
  });

  test('avond en ochtend overschrijven elkaar niet', () async {
    final store = PrefsMomentPlanStore();
    await store.saveEvening(EveningPlan.initial());
    expect(await store.loadMorning(), isNull);
  });

  test('beschadigde of onbekende opslag geeft geen plan en geen fout',
      () async {
    SharedPreferences.setMockInitialValues({
      'moment_plan_evening': '{kapot',
      'moment_plan_morning': jsonEncode({'version': 99, 'plan': {}}),
    });
    final store = PrefsMomentPlanStore();
    expect(await store.loadEvening(), isNull);
    expect(await store.loadMorning(), isNull);
  });

  test('onleesbare delen vallen terug op de beginwaarden', () {
    final plan = EveningPlan.fromJson({
      'days': [
        {'weekday': 1, 'enabled': true, 'bedtime_minutes': 99999},
        'rommel',
      ],
      'steps': [
        {'title': 'Ok', 'duration_min': 9999},
        {'geen': 'titel'},
      ],
      'end': 'onbekend',
    });
    expect(plan.days, hasLength(7));
    expect(plan.days.first.bedtimeMinutes,
        EveningPlan.initial().days.first.bedtimeMinutes);
    expect(plan.steps, [const RoutineStepData(title: 'Ok', durationMin: 180)]);
    expect(plan.end, EveningEnd.atBedtime);
    expect(EveningPlan.fromJson('niets').steps, starterEveningSteps);
  });

  testWidgets('de avondpagina toont het bewaarde plan en bewaart wijzigingen',
      (tester) async {
    // Een plan uit de oude opslag wordt bij het openen overgenomen.
    await tester.runAsync(() => PrefsMomentPlanStore().saveEvening(
        EveningPlan.initial().copyWith(
            steps: const [RoutineStepData(title: 'Journal', durationMin: 10)])));
    final db = await _open(tester, const SavedEveningScreen());
    await tester.pumpAndSettle();
    expect(find.text('Journal'), findsWidgets);
    expect(find.text('Shower'), findsNothing);

    await tester.ensureVisible(find.text('Add step'));
    await tester.tap(find.text('Add step'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tea'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save evening'));
    await tester.pumpAndSettle();

    expect(find.text('Evening saved'), findsOneWidget);
    expect(find.text('Save evening'), findsNothing, reason: 'pagina gesloten');
    final saved = await tester
        .runAsync(() => DbMomentPlanStore(MomentPlanRepository(db)).loadEvening());
    expect(saved!.steps.map((s) => s.title), ['Journal', 'Tea']);
    await _close(tester);
  });

  testWidgets('een eerste keer begint met de starterstappen', (tester) async {
    await _open(tester, const SavedMorningScreen());
    await tester.pumpAndSettle();
    expect(find.text('Breakfast'), findsWidgets);
    await _close(tester);
  });

  testWidgets('mislukt opslaan toont een fout en houdt de pagina open',
      (tester) async {
    await _open(tester, const SavedEveningScreen(), store: _FailingStore());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save evening'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not save your Evening'), findsOneWidget);
    expect(find.text('Evening saved'), findsNothing);
    expect(find.text('Save evening'), findsOneWidget);
    await _close(tester);
  });
}
