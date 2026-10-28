import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/moments/moment_blocking.dart';
import 'package:rest4more/data/moments/moment_profiles.dart';
import 'package:rest4more/data/moments/session_runner.dart';
import 'package:rest4more/data/repositories/focus_session_repository.dart';
import 'package:rest4more/providers/database_providers.dart';
import 'package:rest4more/providers/repository_providers.dart';
import 'package:rest4more/screens/moments_screen.dart';
import 'package:rest4more/screens/session_run_screen.dart';
import 'package:rest4more/screens/session_setup_screen.dart';

import '../data/test_support.dart';
import 'onboarding_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/flow');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  screenTest('elk moment opent hetzelfde openingsscherm', (tester) async {
    for (final entry in {
      'Focus': 'Start Focus',
      'Reading': 'Start Reading',
      'Evening': 'Plan your evening',
      'Morning': 'Plan your morning',
    }.entries) {
      await pumpScreen(tester, const MomentsScreen());
      await tester.ensureVisible(
          find.widgetWithText(TextButton, 'Begin').at(_index(entry.key)));
      await tester.tap(
          find.widgetWithText(TextButton, 'Begin').at(_index(entry.key)));
      await tester.pumpAndSettle();
      expect(find.text('A GENTLE REMINDER'), findsOneWidget, reason: entry.key);
      expect(find.text(entry.value), findsOneWidget, reason: entry.key);
      expect(find.text('Moments'), findsOneWidget, reason: entry.key);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  screenTest('Focus en Reading hebben geen NFC meer in de weg', (tester) async {
    await pumpScreen(tester, const MomentsScreen());
    await tester.tap(find.widgetWithText(TextButton, 'Begin').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Focus'));
    await tester.pumpAndSettle();
    // De instellingen van de timer, niet het NFC-prototype.
    expect(find.text('How long'), findsOneWidget);
    expect(find.textContaining('NFC'), findsNothing);
    expect(find.textContaining('tag'), findsNothing);
  });

  screenTest('de lopende sessie telt af, vraagt om bevestiging en logt '
      'stoppedEarly', (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);
    final runner = SessionRunner(
      FocusSessionRepository(db),
      MomentBlocking(container.read(momentProfileServiceProvider),
          channel: channel, isAndroid: true, isIos: false),
      platform: SessionPlatform.android,
    );
    final profile = await tester
        .runAsync(() => container.read(momentProfileServiceProvider).ensure(MomentKind.focus));

    await pumpScreen(
      tester,
      UncontrolledProviderScope(
        container: ProviderContainer(overrides: [
          databaseProvider.overrideWithValue(db),
          sessionRunnerProvider.overrideWithValue(runner),
        ]),
        child: SessionRunScreen(
          setup: FocusSetup(
            kind: SessionKind.focus,
            minutes: 25,
            blockProfileId: profile!.id,
          ),
        ),
      ),
      db: db,
    );
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('End early'), findsOneWidget);
    expect(find.textContaining('24:'), findsOneWidget);
    expect(find.textContaining('Your apps are set aside until'), findsOneWidget);

    await tester.tap(find.text('End early'));
    await tester.pumpAndSettle();
    expect(find.text('End this session early?'), findsOneWidget);
    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();
    expect(find.text('End early'), findsOneWidget, reason: 'bleef doorlopen');

    await tester.tap(find.text('End early'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'End early'));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Session ended'), findsOneWidget);
    final rows = await tester.runAsync(() => db.select(db.focusSessions).get());
    expect(rows!.single.outcome, SessionOutcome.stoppedEarly);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

/// Volgorde van de kaarten op het Moments-scherm: Focus, Reading, Tag, Evening,
/// Morning.
int _index(String title) => switch (title) {
      'Focus' => 0,
      'Reading' => 1,
      'Evening' => 3,
      'Morning' => 4,
      _ => throw ArgumentError(title),
    };
