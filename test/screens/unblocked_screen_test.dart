import 'package:flutter/material.dart';
import 'package:rest4more/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/moments/moment_blocking.dart';
import 'package:rest4more/data/moments/moment_profiles.dart';
import 'package:rest4more/data/moments/session_runner.dart';
import 'package:rest4more/data/moments/unblock_service.dart';
import 'package:rest4more/data/repositories/focus_session_repository.dart';
import 'package:rest4more/providers/database_providers.dart';
import 'package:rest4more/providers/repository_providers.dart';
import 'package:rest4more/screens/session_run_screen.dart';
import 'package:rest4more/screens/session_setup_screen.dart';
import 'package:rest4more/screens/unblocked_screen.dart';

import '../data/test_support.dart';
import 'onboarding_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/unblocked');
  late List<MethodCall> calls;
  Object? failRevokeWith;

  setUp(() {
    calls = [];
    failRevokeWith = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'revokeUnblock' && failRevokeWith != null) {
            throw failRevokeWith!;
          }
          return null;
        });
  });

  List<String> methods() => [for (final c in calls) c.method];

  Future<void> wait(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }

  /// Een Reading-sessie van 10:00 tot 11:24, met de apps vrij van 10:50 tot
  /// 10:57. Het scherm ligt op een lege pagina, zodat terug te zien is.
  Future<({AppDatabase db, TestClock clock, SessionRunner runner})> open(
    WidgetTester tester, {
    DateTime? at,
  }) async {
    final db = memoryDb();
    addTearDown(db.close);
    final clock = TestClock(DateTime(2026, 10, 12, 10));
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    final runner = SessionRunner(
      FocusSessionRepository(db, now: clock.call),
      MomentBlocking(
        container.read(momentProfileServiceProvider),
        channel: channel,
        isAndroid: true,
        isIos: false,
      ),
      now: clock.call,
      platform: SessionPlatform.android,
    );
    final session = await tester.runAsync(() async {
      await runner.start(kind: MomentKind.reading, minutes: 84);
      clock.current = DateTime(2026, 10, 12, 10, 50);
      return runner.pauseForUnblock(
        until: DateTime(2026, 10, 12, 10, 57),
        minutes: 7,
      );
    });
    clock.current = at ?? DateTime(2026, 10, 12, 10, 50, 12);
    final service = UnblockService(
      channel: channel,
      isAndroid: true,
      isIos: false,
      now: clock.call,
    );

    await pumpScreen(
      tester,
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sessionRunnerProvider.overrideWithValue(runner),
          unblockServiceProvider.overrideWithValue(service),
        ],
        // Een eigen navigator onder de overrides, zodat ook nieuwe pagina's
        // ze zien.
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => UnblockedScreen(
                        until: DateTime(2026, 10, 12, 10, 57),
                        granted: const Duration(minutes: 7),
                        session: session,
                        now: clock.call,
                      ),
                    ),
                  ),
                  child: const Text('Reading'),
                ),
              ),
            ),
          ),
        ),
      ),
      db: db,
    );
    await tester.tap(find.text('Reading'));
    await tester.pumpAndSettle();
    return (db: db, clock: clock, runner: runner);
  }

  screenTest('A1: apps vrij, aftellen en de stilstaande focustimer', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final t = await open(tester);

    expect(find.text('APPS AVAILABLE'), findsOneWidget);
    expect(find.text('Apps unlocked'), findsOneWidget);
    expect(find.text('06:48'), findsOneWidget);
    expect(find.text('Your apps lock again at 10:57.'), findsOneWidget);
    expect(find.text('Focus timer paused'), findsOneWidget);
    expect(find.text('Reading · 34:00 remaining'), findsOneWidget);
    expect(find.text('Block apps again'), findsOneWidget);
    expect(
      find.text('Blocks your apps now and resumes your focus timer.'),
      findsOneWidget,
    );
    expect(find.text('Done'), findsNothing);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      closeTo(408 / 420, 0.001),
    );

    // Een minuut later: de vrije tijd telt af, de focustimer staat stil.
    t.clock.advance(const Duration(minutes: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('05:48'), findsOneWidget);
    expect(find.text('Reading · 34:00 remaining'), findsOneWidget);

    expect(find.bySemanticsLabel('Apps lock again in 6 min'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Focus timer paused. Reading, 34 min remaining'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  screenTest('A2: in de laatste minuut "Almost time" in terracotta', (
    tester,
  ) async {
    final t = await open(tester, at: DateTime(2026, 10, 12, 10, 55, 59));
    expect(find.text('Apps unlocked'), findsOneWidget, reason: 'nog 61 s');

    t.clock.advance(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('LOCKING SOON'), findsOneWidget);
    expect(find.text('Almost time'), findsOneWidget);
    expect(find.text('00:59'), findsOneWidget);
    expect(find.text('Apps lock in under a minute.'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('00:59')).style!.color,
      const Color(0xFFAA7657),
    );
    expect(find.text('Reading · 34:00 remaining'), findsOneWidget);
  });

  screenTest('"Block apps again" blokkeert meteen, hervat de timer en gaat '
      'terug', (tester) async {
    final t = await open(tester);
    t.clock.current = DateTime(2026, 10, 12, 10, 54);

    await tester.tap(find.text('Block apps again'));
    await wait(tester);
    await tester.pumpAndSettle();

    expect(methods(), contains('revokeUnblock'));
    expect(find.byType(UnblockedScreen), findsNothing);
    expect(find.text('Reading'), findsOneWidget, reason: 'terug');

    final row = (await tester.runAsync(
      () => t.db.select(t.db.focusSessions).get(),
    ))!.single;
    expect(row.events.last.event, SessionEventType.unblockEnded);
    final fresh = (await tester.runAsync(t.runner.current))!;
    expect(fresh.isPaused(t.clock.call()), isFalse);
    expect(fresh.pausedFor(t.clock.call()), const Duration(minutes: 4));
    expect(
      fresh.remaining(t.clock.call()),
      const Duration(minutes: 34),
      reason: 'verder waar hij stond',
    );
    expect(
      fresh
          .endsAt(t.clock.call())
          .isAtSameMomentAs(DateTime(2026, 10, 12, 11, 28)),
      isTrue,
      reason: '11:24 schuift 4 minuten op',
    );
  });

  screenTest('mislukt dichtzetten: de apps blijven vrij en je kunt opnieuw', (
    tester,
  ) async {
    failRevokeWith = PlatformException(code: 'x');
    await open(tester);
    await tester.tap(find.text('Block apps again'));
    await wait(tester);
    expect(find.textContaining('could not block'), findsOneWidget);
    expect(find.byType(UnblockedScreen), findsOneWidget);
    expect(find.text('Block apps again'), findsOneWidget);
  });

  screenTest('om 00:00 gaat alles vanzelf weer dicht', (tester) async {
    final t = await open(tester, at: DateTime(2026, 10, 12, 10, 56, 58));
    t.clock.advance(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    await wait(tester);
    await tester.pumpAndSettle();

    expect(methods(), contains('revokeUnblock'));
    expect(find.byType(UnblockedScreen), findsNothing);
  });

  screenTest('terug doet niets: de apps gaan niet stil dicht', (tester) async {
    await open(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(UnblockedScreen), findsOneWidget);
    expect(methods(), isNot(contains('revokeUnblock')));
  });

  screenTest('van Reading via "Need an app?" en terug: timer bevroren, dan '
      'hervat', (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    final runner = SessionRunner(
      FocusSessionRepository(db),
      MomentBlocking(
        container.read(momentProfileServiceProvider),
        channel: channel,
        isAndroid: true,
        isIos: false,
      ),
      platform: SessionPlatform.android,
    );
    final profile = await tester.runAsync(
      () => container
          .read(momentProfileServiceProvider)
          .ensure(MomentKind.reading),
    );
    final service = UnblockService(
      channel: channel,
      isAndroid: false,
      isIos: true,
    );

    await pumpScreen(
      tester,
      UncontrolledProviderScope(
        container: ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            sessionRunnerProvider.overrideWithValue(runner),
            unblockServiceProvider.overrideWithValue(service),
          ],
        ),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SessionRunScreen(
            setup: FocusSetup(
              kind: SessionKind.reading,
              minutes: 40,
              blockProfileId: profile!.id,
            ),
          ),
        ),
      ),
      db: db,
    );
    await wait(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Need an app?'), findsOneWidget);

    await tester.tap(find.text('Need an app?'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 6));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unblock'));
    await wait(tester);
    await tester.pump();

    expect(methods(), contains('grantUnblock'));
    expect(find.text('Apps unlocked'), findsOneWidget);
    expect(find.text('Focus timer paused'), findsOneWidget);
    final paused = (await tester.runAsync(runner.current))!;
    expect(paused.isPaused(DateTime.now()), isTrue);

    await tester.tap(find.text('Block apps again'));
    for (var i = 0; i < 5; i++) {
      await wait(tester);
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(methods(), contains('revokeUnblock'));
    expect(find.byType(UnblockedScreen), findsNothing);
    expect(find.text('End early'), findsOneWidget, reason: 'terug bij Reading');
    expect(find.textContaining('Focus resumed · paused for'), findsOneWidget);
    final resumed = (await tester.runAsync(runner.current))!;
    expect(resumed.isPaused(DateTime.now()), isFalse);
    expect(resumed.pausedFor(DateTime.now()), greaterThan(Duration.zero));

    // De melding verdwijnt na een paar seconden.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.textContaining('Focus resumed'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
