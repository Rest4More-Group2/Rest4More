import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/converters.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/moments/strict_night_log.dart';
import 'package:rest4more/data/progress/moment_records.dart';
import 'package:rest4more/data/repositories/focus_session_repository.dart';
import 'package:rest4more/data/repositories/session_end_reason_repository.dart';
import 'package:rest4more/data/sync/sync_tables.dart';

import '../data/test_support.dart';

class _MemoryStash implements StrictNightStash {
  DateTime? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<DateTime?> read() async => value;

  @override
  Future<void> write(DateTime startedAt) async => value = startedAt;
}

void main() {
  test('alleen echte momenten tellen; pauzes en tijd zonder blokkade niet als '
      'beschermd', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final clock = TestClock(DateTime(2026, 11, 16, 21));
    final repo = FocusSessionRepository(db, now: clock.call);

    // Afgerond, 40 minuten, waarvan 10 minuten een app vrij.
    final ok = await startSession(repo, upTo: SessionState.activating);
    await repo.markBlockingConfirmed(ok.id);
    await repo.transition(ok.id, SessionState.active);
    clock.advance(const Duration(minutes: 10));
    await repo.logEvent(
      ok.id,
      SessionEventData(
        at: clock().toUtc(),
        event: SessionEventType.unblockGranted,
        minutes: 10,
      ),
    );
    clock.advance(const Duration(minutes: 30));
    await repo.transition(ok.id, SessionState.releasing);
    await repo.markBlockingReleased(ok.id);
    await repo.finish(ok.id, SessionOutcome.completed);

    // Eerder gestopt, zonder bevestigde blokkade.
    final early = await startSession(repo, upTo: SessionState.selecting);
    clock.advance(const Duration(minutes: 15));
    await repo.transition(early.id, SessionState.activating);
    await repo.finish(early.id, SessionOutcome.cancelled);

    final stopped = await repo.recordFinished(
      mode: 'focus',
      source: SessionSource.manual,
      platform: SessionPlatform.android,
      startedAt: DateTime(2026, 11, 17, 21),
      endedAt: DateTime(2026, 11, 17, 21, 20),
      outcome: SessionOutcome.stoppedEarly,
    );

    final reasons = SessionEndReasonRepository(db);
    await reasons.set(stopped.id, EndReason.notification);

    final sessions = await db.select(db.focusSessions).get();
    final records = momentRecords(sessions, await reasons.watchAll().first);
    expect(records, hasLength(2));

    final done = records.firstWhere((r) => r.id == ok.id);
    expect(done.endedEarly, isFalse);
    expect(done.focused, const Duration(minutes: 30));
    expect(done.protected, const Duration(minutes: 30));
    expect(done.blocked, const Duration(minutes: 40));
    expect(done.reason, isNull);

    final s = records.firstWhere((r) => r.id == stopped.id);
    expect(s.endedEarly, isTrue);
    expect(s.focused, const Duration(minutes: 20));
    expect(s.protected, Duration.zero);
    expect(s.reason, EndReason.notification);
  });

  test('een reden overschrijven en wissen', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final repo = FocusSessionRepository(db);
    final s = await repo.recordFinished(
      mode: 'focus',
      source: SessionSource.manual,
      platform: SessionPlatform.android,
      startedAt: DateTime(2026, 11, 17, 21),
      endedAt: DateTime(2026, 11, 17, 21, 20),
      outcome: SessionOutcome.stoppedEarly,
    );
    final reasons = SessionEndReasonRepository(db);
    await reasons.set(s.id, EndReason.other);
    await reasons.set(s.id, EndReason.justWanted);
    expect(await reasons.watchAll().first, {s.id: EndReason.justWanted});
    await reasons.set(s.id, null);
    expect(await reasons.watchAll().first, isEmpty);
  });

  test('redenen gaan niet mee met de sync', () {
    final db = memoryDb();
    addTearDown(db.close);
    final names = syncTableSpecs(db).map((t) => t.name);
    expect(names, isNot(contains('session_end_reasons')));
    expect(
      db.focusSessions.$columns.map((c) => c.name),
      isNot(contains('end_reason')),
    );
  });

  group('strakke avond', () {
    test('eerder gestopt voor 06:00 de ochtend erna', () {
      final start = DateTime(2026, 11, 16, 22);
      expect(strictNightEndedEarly(start, DateTime(2026, 11, 16, 23, 30)),
          isTrue);
      expect(strictNightEndedEarly(start, DateTime(2026, 11, 17, 5, 59)),
          isTrue);
      expect(strictNightEndedEarly(start, DateTime(2026, 11, 17, 6)), isFalse);
      expect(strictNightEndedEarly(start, DateTime(2026, 11, 17, 7, 15)),
          isFalse);
    });

    test('begonnen na middernacht: de grens is 06:00 diezelfde ochtend', () {
      final start = DateTime(2026, 11, 17, 0, 30);
      expect(strictNightEndedEarly(start, DateTime(2026, 11, 17, 3)), isTrue);
      expect(strictNightEndedEarly(start, DateTime(2026, 11, 17, 6, 30)),
          isFalse);
    });

    test('vastleggen na de kaart, met het begin uit de opslag', () async {
      final db = memoryDb();
      addTearDown(db.close);
      final clock = TestClock(DateTime(2026, 11, 16, 22));
      final stash = _MemoryStash();
      final log = StrictNightLog(
        FocusSessionRepository(db, now: clock.call),
        stash,
        now: clock.call,
      );

      expect(await log.end(mode: 'evening'), isNull);

      await log.begin();
      clock.advance(const Duration(hours: 1, minutes: 30));
      final result = (await log.end(mode: 'evening'))!;
      expect(result.endedEarly, isTrue);
      expect(stash.value, isNull);

      final row = await db.select(db.focusSessions).getSingle();
      expect(row.id, result.sessionId);
      expect(row.outcome, SessionOutcome.stoppedEarly);
      expect(row.source, SessionSource.nfc);
      expect(row.state, SessionState.completed);
      expect(row.endedAt, isNotNull);
      expect(row.blockingConfirmedAt, isNotNull);
      expect(
        row.endedAt!.difference(row.startedAt),
        const Duration(hours: 1, minutes: 30),
      );
      // Er staat geen open sessie meer, dus een nieuw moment kan starten.
      expect(await FocusSessionRepository(db).findOpen(), isNull);
    });
  });
}
