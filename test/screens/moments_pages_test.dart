import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/moments/moment_plans.dart';
import 'package:rest4more/data/moments/moment_schedule.dart';
import 'package:rest4more/screens/evening_screen.dart';
import 'package:rest4more/screens/session_setup_screen.dart';
import 'package:rest4more/screens/morning_screen.dart';
import 'package:rest4more/screens/moments_screen.dart';

import 'onboarding_test_support.dart';

void main() {
  screenTest('Moments toont Focus, Evening en Morning', (tester) async {
    await pumpScreen(tester, const MomentsScreen());
    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('Reading'), findsOneWidget);
    expect(find.text('Evening'), findsOneWidget);
    expect(find.text('Morning'), findsOneWidget);
  });

  screenTest('Reading: eigen presets en een eigen profiel bij het starten',
      (tester) async {
    FocusSetup? started;
    final db = await pumpScreen(
      tester,
      SessionSetupScreen(
          kind: SessionKind.reading, onStart: (s) => started = s),
    );
    expect(find.text('Chapter · 40 min'), findsOneWidget);
    expect(find.text('No apps chosen yet.'), findsOneWidget);
    await tester.tap(find.text('Start Reading'));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(started?.kind, SessionKind.reading);
    expect(started?.minutes, 40);
    final profiles =
        await tester.runAsync(() => db.select(db.blockProfiles).get());
    expect(profiles!.map((p) => p.name), ['Reading']);
    expect(started?.blockProfileId, profiles.single.id);
  });

  screenTest('Focus geeft de gekozen duur door', (tester) async {
    FocusSetup? started;
    await pumpScreen(tester, SessionSetupScreen(onStart: (s) => started = s));
    await tester.tap(find.textContaining('Deep'));
    await tester.pump();
    await tester.tap(find.text('Start Focus'));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    expect(started?.minutes, 90);
  });

  screenTest('Focus: eigen duur stapt per 5 minuten', (tester) async {
    FocusSetup? started;
    await pumpScreen(tester, SessionSetupScreen(onStart: (s) => started = s));
    await tester.tap(find.text('Custom'));
    await tester.pump();
    await tester.tap(find.byTooltip('More minutes'));
    await tester.pump();
    await tester.tap(find.text('Start Focus'));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    expect(started?.minutes, 35);
  });

  screenTest('Early stop vraagt eerst bevestiging', (tester) async {
    bool? result;
    await pumpScreen(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await confirmStopEarly(context),
          child: const Text('stop'),
        ),
      ),
    );
    await tester.tap(find.text('stop'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    await tester.tap(find.text('stop'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End early'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  screenTest('Evening telt terug over de stappen en slaat het plan op',
      (tester) async {
    EveningPlan? saved;
    await pumpScreen(
      tester,
      EveningScreen(now: DateTime(2026, 10, 12), onSave: (p) => saved = p),
    );
    // Maandag 22:30 bedtijd, stappen samen 60 min, heads-up 30 min eerder.
    expect(find.text('21:00'), findsOneWidget); // heads-up
    expect(find.text('21:30'), findsOneWidget); // eerste stap
    expect(find.text('Bedtime · blocking ends'), findsOneWidget);
    await tester.ensureVisible(find.textContaining('At the next scan'));
    await tester.tap(find.textContaining('At the next scan'));
    await tester.pump();
    expect(find.textContaining('Strict overnight'), findsOneWidget);
    await tester.tap(find.text('Save evening'));
    await tester.pump();
    expect(saved?.end, EveningEnd.atNextScan);
    expect(saved?.steps, hasLength(5));
  });

  screenTest('Evening: een stap weghalen schuift de start later',
      (tester) async {
    await pumpScreen(tester, EveningScreen(now: DateTime(2026, 10, 12)));
    await tester.ensureVisible(find.byTooltip('Remove Read'));
    await tester.tap(find.byTooltip('Remove Read'));
    await tester.pump();
    // 35 min over: de avond begint om 21:55.
    expect(find.text('21:55'), findsOneWidget);
    expect(find.text('Total 35 min'), findsOneWidget);
  });

  screenTest('Evening: een eigen stap toevoegen', (tester) async {
    EveningPlan? saved;
    await pumpScreen(
      tester,
      EveningScreen(now: DateTime(2026, 10, 12), onSave: (p) => saved = p),
    );
    await tester.ensureVisible(find.text('Add step'));
    await tester.tap(find.text('Add step'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tea'));
    await tester.pumpAndSettle();
    expect(find.text('Total 1 h 10 min'), findsOneWidget);
    await tester.tap(find.text('Save evening'));
    await tester.pump();
    expect(saved?.steps.last.title, 'Tea');
  });

  screenTest('Zonder stappen kan een avond niet bewaard worden',
      (tester) async {
    await pumpScreen(
      tester,
      EveningScreen(
        now: DateTime(2026, 10, 12),
        initial: EveningPlan.initial().copyWith(steps: const []),
        onSave: (_) {},
      ),
    );
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.text('No steps yet. Add the first one.'), findsOneWidget);
  });

  screenTest('Morning rekent het einde uit de stappen', (tester) async {
    await pumpScreen(tester, MorningScreen(now: DateTime(2026, 10, 12)));
    // 07:00 + 55 min.
    expect(find.text('07:55'), findsOneWidget);
    expect(find.text('Your phone is back'), findsOneWidget);
  });
}
