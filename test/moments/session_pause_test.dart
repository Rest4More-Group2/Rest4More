import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/converters.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/moments/moment_blocking.dart';
import 'package:rest4more/data/moments/moment_profiles.dart';
import 'package:rest4more/data/moments/session_pauses.dart';
import 'package:rest4more/data/moments/session_runner.dart';
import 'package:rest4more/data/repositories/focus_session_repository.dart';
import 'package:rest4more/providers/database_providers.dart';
import 'package:rest4more/providers/repository_providers.dart';

import '../data/test_support.dart';

/// Het voorbeeld uit het ontwerp: Reading van 10:00 tot 11:24.
final _start = DateTime(2026, 10, 12, 10);
const _planned = Duration(minutes: 84);

DateTime _at(int hour, int minute, [int second = 0]) =>
    DateTime(2026, 10, 12, hour, minute, second);

SessionEventData _granted(DateTime at, int minutes) => SessionEventData(
  at: at.toUtc(),
  event: SessionEventType.unblockGranted,
  minutes: minutes,
);

SessionEventData _ended(DateTime at) =>
    SessionEventData(at: at.toUtc(), event: SessionEventType.unblockEnded);

/// Hetzelfde moment, of de tijd nu in UTC of lokaal staat.
Matcher _sameMoment(DateTime t) =>
    predicate<DateTime>((d) => d.isAtSameMomentAs(t), 'same moment as $t');

RunningSession _session(List<SessionEventData> events) => RunningSession(
  id: 's',
  kind: MomentKind.reading,
  startedAt: _start,
  planned: _planned,
  pauses: pausesFromEvents(events),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('pauzes uit het logboek', () {
    test('zonder pauze verandert er niets', () {
      final s = _session(const []);
      expect(s.endsAt(_at(10, 30)), _sameMoment(_at(11, 24)));
      expect(s.remaining(_at(10, 30)), const Duration(minutes: 54));
      expect(s.isPaused(_at(10, 30)), isFalse);
    });

    test('tijdens de vrijgave staat de timer stil', () {
      final s = _session([_granted(_at(10, 46, 48), 10)]);
      final frozen = s.remaining(_at(10, 46, 48));
      for (final now in [_at(10, 47), _at(10, 50), _at(10, 56, 30)]) {
        expect(s.isPaused(now), isTrue);
        expect(s.remaining(now), frozen, reason: '$now');
        expect(s.isOver(now), isFalse);
      }
    });

    test('"Block apps again" na 4 minuten: het einde schuift 4 minuten op', () {
      final s = _session([_granted(_at(10, 47), 10), _ended(_at(10, 51))]);
      final now = _at(10, 52);
      expect(s.isPaused(now), isFalse);
      expect(s.pausedFor(now), const Duration(minutes: 4));
      expect(s.endsAt(now), _sameMoment(_at(11, 28)));
      expect(
        s.remaining(_at(10, 51)),
        s.remaining(_at(10, 47)),
        reason: 'loopt verder waar hij stond',
      );
    });

    test('vanzelf dicht, ook als de app dicht was: de hele vrijgave telt', () {
      // Geen "unblockEnded": de app was op de achtergrond of afgesloten.
      final s = _session([_granted(_at(10, 47), 10)]);
      final back = _at(11, 10);
      expect(s.isPaused(back), isFalse);
      expect(s.pausedFor(back), const Duration(minutes: 10));
      expect(s.endsAt(back), _sameMoment(_at(11, 34)));
      expect(s.remaining(back), const Duration(minutes: 24));
    });

    test('een te laat vastgelegd einde verlengt de pauze niet', () {
      final s = _session([_granted(_at(10, 47), 5), _ended(_at(11, 5))]);
      expect(s.pausedFor(_at(11, 6)), const Duration(minutes: 5));
    });

    test(
      'meerdere keren: de pauzes tellen op en het einde schuift elke keer',
      () {
        final events = [
          _granted(_at(10, 10), 5),
          _ended(_at(10, 12)), // 2 min
        ];
        expect(_session(events).endsAt(_at(10, 20)), _sameMoment(_at(11, 26)));

        events.add(_granted(_at(10, 30), 10)); // vanzelf dicht: 10 min
        expect(_session(events).endsAt(_at(10, 50)), _sameMoment(_at(11, 36)));

        events
          ..add(_granted(_at(11, 0), 15))
          ..add(_ended(_at(11, 1))); // 1 min
        final s = _session(events);
        expect(s.pausedFor(_at(11, 5)), const Duration(minutes: 13));
        expect(s.endsAt(_at(11, 5)), _sameMoment(_at(11, 37)));
      },
    );

    test('twee vrijgaven die elkaar overlappen tellen één keer', () {
      final s = _session([
        _granted(_at(10, 10), 10),
        _granted(_at(10, 15), 10),
      ]);
      expect(s.pausedFor(_at(11, 0)), const Duration(minutes: 15));
      expect(s.activePause(_at(10, 18))!.until, _sameMoment(_at(10, 25)));
    });

    test('"unblockEnded" sluit elke pauze die dan liep', () {
      final s = _session([
        _granted(_at(10, 10), 10),
        _granted(_at(10, 12), 10),
        _ended(_at(10, 14)),
      ]);
      expect(s.isPaused(_at(10, 15)), isFalse);
      expect(s.pausedFor(_at(10, 30)), const Duration(minutes: 4));
    });

    test('een sessie die midden in een pauze zou eindigen, eindigt niet', () {
      // Nog 2 minuten over als de apps 10 minuten vrij gaan.
      final s = _session([_granted(_at(11, 22), 10)]);
      expect(s.isOver(_at(11, 25)), isFalse);
      expect(s.isOver(_at(11, 33)), isFalse);
      expect(s.isOver(_at(11, 34)), isTrue);
    });
  });

  group('SessionRunner', () {
    const channel = MethodChannel('test/pause');
    late AppDatabase db;
    late TestClock clock;
    late ProviderContainer container;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => null);
      db = memoryDb();
      clock = TestClock(_start);
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
    });

    SessionRunner runner() => SessionRunner(
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

    test(
      'pauzeren en hervatten via het logboek, ook na een herstart',
      () async {
        final r = runner();
        await r.start(kind: MomentKind.reading, minutes: 84);
        clock.current = _at(10, 47);
        final paused = await r.pauseForUnblock(until: _at(10, 57), minutes: 10);
        expect(paused!.isPaused(clock.call()), isTrue);

        // Een nieuwe runner op dezelfde database: zoals na het herstarten.
        clock.current = _at(10, 50);
        final restored = (await runner().current())!;
        expect(restored.isPaused(clock.call()), isTrue);
        expect(
          restored.activePause(clock.call())!.until,
          _sameMoment(_at(10, 57)),
        );
        expect(restored.remaining(clock.call()), const Duration(minutes: 37));

        clock.current = _at(10, 51);
        final resumed = (await r.resumeAfterUnblock(restored.id))!;
        expect(resumed.isPaused(clock.call()), isFalse);
        expect(resumed.endsAt(clock.call()), _sameMoment(_at(11, 28)));
        expect(resumed.remaining(clock.call()), const Duration(minutes: 37));
      },
    );

    test('vanzelf dicht terwijl de app op de achtergrond stond', () async {
      final r = runner();
      await r.start(kind: MomentKind.reading, minutes: 84);
      clock.current = _at(10, 47);
      await r.pauseForUnblock(until: _at(10, 52), minutes: 5);

      clock.current = _at(11, 0);
      final back = (await r.current())!;
      expect(back.isPaused(clock.call()), isFalse);
      expect(back.pausedFor(clock.call()), const Duration(minutes: 5));
      expect(back.endsAt(clock.call()), _sameMoment(_at(11, 29)));
    });

    test('focustijd in het logboek telt de vrije tijd niet mee', () async {
      final r = runner();
      final running = await r.start(kind: MomentKind.reading, minutes: 84);
      clock.current = _at(10, 47);
      await r.pauseForUnblock(until: _at(10, 57), minutes: 10);
      clock.current = _at(10, 51);
      await r.resumeAfterUnblock(running.id);
      clock.current = _at(11, 28);
      await r.end((await r.current())!, early: false);

      final row = (await db.select(db.focusSessions).get()).single;
      expect(row.outcome, SessionOutcome.completed);
      expect(focusedTime(row, clock.call()), _planned);
    });

    test('een sessie die al om is, wordt niet meer gepauzeerd', () async {
      final r = runner();
      await r.start(kind: MomentKind.focus, minutes: 10);
      clock.current = _at(10, 11);
      expect(await r.pauseForUnblock(until: _at(10, 16), minutes: 5), isNull);
    });

    test('watchCurrent geeft de pauze door aan andere schermen', () async {
      final r = runner();
      await r.start(kind: MomentKind.focus, minutes: 25);
      final seen = <bool>[];
      final sub = r.watchCurrent().listen(
        (s) => seen.add(s?.isPaused(clock.call()) ?? false),
      );
      addTearDown(sub.cancel);
      await pumpEventQueue();
      await r.pauseForUnblock(
        until: _start.add(const Duration(minutes: 5)),
        minutes: 5,
      );
      await pumpEventQueue();
      expect(seen.first, isFalse);
      expect(seen.last, isTrue);
    });
  });
}
