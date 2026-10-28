import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/moments/moment_blocking.dart';
import 'package:rest4more/data/moments/moment_profiles.dart';
import 'package:rest4more/data/moments/session_runner.dart';
import 'package:rest4more/data/repositories/focus_session_repository.dart';
import 'package:rest4more/providers/database_providers.dart';
import 'package:rest4more/providers/repository_providers.dart';

import '../data/test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/runner');
  late AppDatabase db;
  late TestClock clock;
  late FocusSessionRepository sessions;
  late MomentProfileService service;
  late SessionRunner runner;
  late List<MethodCall> calls;
  Object? failBlockWith;
  Object? failReleaseWith;

  setUp(() {
    failBlockWith = null;
    failReleaseWith = null;
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'setBlocking') {
        final on = (call.arguments as Map)['isBlocking'] as bool;
        if (on && failBlockWith != null) throw failBlockWith!;
        if (!on && failReleaseWith != null) throw failReleaseWith!;
      }
      return null;
    });
    db = memoryDb();
    clock = TestClock(DateTime(2026, 10, 12, 9));
    sessions = FocusSessionRepository(db, now: clock.call);
    final container =
        ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    service = container.read(momentProfileServiceProvider);
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    runner = SessionRunner(
      sessions,
      MomentBlocking(service, channel: channel, isAndroid: true, isIos: false),
      now: clock.call,
      platform: SessionPlatform.android,
    );
  });

  Future<List<FocusSession>> all() => db.select(db.focusSessions).get();
  List<String> blockingCalls() => [
        for (final c in calls)
          if (c.method == 'setBlocking') '${(c.arguments as Map)['isBlocking']}',
      ];

  test('starten blokkeert de apps van dat moment en wordt pas dan actief',
      () async {
    await service.saveAndroidPackages(MomentKind.reading, {'read.app'});
    await service.saveAndroidPackages(MomentKind.focus, {'focus.app'});
    final running = await runner.start(kind: MomentKind.reading, minutes: 40);

    expect(calls.first.method, 'setBlockedPackages');
    expect(calls.first.arguments['blockedPackages'], ['read.app']);
    expect(blockingCalls(), ['true']);
    final row = (await all()).single;
    expect(row.state, SessionState.active);
    expect(row.mode, 'reading');
    expect(row.source, SessionSource.manual);
    expect(row.blockingConfirmedAt, isNotNull);
    expect(row.plannedSeconds, 40 * 60);
    expect(running.endsAt.difference(running.startedAt),
        const Duration(minutes: 40));
  });

  test('mislukt blokkeren: geen actieve sessie en een eerlijke uitkomst',
      () async {
    failBlockWith = PlatformException(code: 'nope');
    await expectLater(
      runner.start(kind: MomentKind.focus, minutes: 25),
      throwsA(isA<SessionStartError>()),
    );
    final row = (await all()).single;
    expect(row.state, SessionState.completed);
    expect(row.outcome, SessionOutcome.activationFailed);
    expect(row.blockingConfirmedAt, isNull);
    expect(await sessions.findOpen(), isNull);
  });

  test('eerder stoppen wordt als stoppedEarly vastgelegd', () async {
    final running = await runner.start(kind: MomentKind.focus, minutes: 25);
    clock.advance(const Duration(minutes: 5));
    await runner.end(running, early: true);
    final row = (await all()).single;
    expect(row.outcome, SessionOutcome.stoppedEarly);
    expect(row.blockingReleasedAt, isNotNull);
    expect(blockingCalls(), ['true', 'false']);
  });

  test('uitlopen wordt als completed vastgelegd', () async {
    final running = await runner.start(kind: MomentKind.focus, minutes: 25);
    clock.advance(const Duration(minutes: 25));
    expect(running.isOver(clock.call()), isTrue);
    await runner.end(running, early: false);
    expect((await all()).single.outcome, SessionOutcome.completed);
  });

  test('mislukt vrijgeven: releaseFailed en de apps blijven te herstellen',
      () async {
    final running = await runner.start(kind: MomentKind.focus, minutes: 25);
    failReleaseWith = PlatformException(code: 'nope');
    await expectLater(
      runner.end(running, early: false),
      throwsA(isA<ReleaseFailedError>()),
    );
    final row = (await all()).single;
    expect(row.outcome, SessionOutcome.releaseFailed);
    expect(row.blockingReleasedAt, isNull, reason: 'niet vrijgegeven');

    failReleaseWith = null;
    await runner.releaseBlocking(MomentKind.focus);
    expect(blockingCalls().last, 'false');
  });

  test('een tweede sessie overschrijft de lopende nooit stil', () async {
    final first = await runner.start(kind: MomentKind.focus, minutes: 25);
    clock.advance(const Duration(minutes: 1));
    await expectLater(
      runner.start(kind: MomentKind.reading, minutes: 20),
      throwsA(isA<SessionRunningError>()
          .having((e) => e.running.id, 'id', first.id)),
    );
    expect(await all(), hasLength(1));
    expect((await runner.current())!.id, first.id);
  });

  test('een verlopen sessie van een gesloten app wordt eerst afgerond',
      () async {
    await runner.start(kind: MomentKind.focus, minutes: 25);
    clock.advance(const Duration(hours: 2));
    final fresh = await runner.start(kind: MomentKind.reading, minutes: 20);

    final rows = await all()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    expect(rows, hasLength(2));
    expect(rows.first.outcome, SessionOutcome.completed);
    expect(rows.first.blockingReleasedAt, isNotNull);
    expect(rows.last.id, fresh.id);
    expect(rows.last.state, SessionState.active);
  });

  test('een afgebroken start wordt geannuleerd en geeft de apps vrij',
      () async {
    final stale = await sessions.start(
      mode: 'focus',
      source: SessionSource.manual,
      platform: SessionPlatform.android,
      plannedSeconds: 600,
    );
    await sessions.transition(stale.id, SessionState.activating);
    await runner.start(kind: MomentKind.focus, minutes: 10);

    final old = (await all()).firstWhere((s) => s.id == stale.id);
    expect(old.outcome, SessionOutcome.cancelled);
    expect(blockingCalls().first, 'false');
  });
}
