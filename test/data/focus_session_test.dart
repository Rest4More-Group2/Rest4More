import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/repositories/focus_session_repository.dart';
import 'package:rest4more/data/repositories/repository_support.dart';
import 'package:rest4more/data/repositories/routine_repository.dart';

import 'test_support.dart';

void main() {
  late AppDatabase db;
  late TestClock clock;
  late FocusSessionRepository repo;

  setUp(() {
    db = memoryDb();
    clock = TestClock();
    repo = FocusSessionRepository(db, now: clock.call);
  });
  tearDown(() => db.close());

  test('legale overgangen voegen events in volgorde toe', () async {
    final session = await repo.start(
      mode: 'focus',
      source: SessionSource.nfc,
      platform: SessionPlatform.ios,
      plannedSeconds: 600,
    );
    expect(session.state, SessionState.selecting);
    expect(session.events, isEmpty);

    for (final to in [
      SessionState.awaitingScan,
      SessionState.activating,
      SessionState.active,
      SessionState.releasing,
    ]) {
      clock.advance(const Duration(seconds: 5));
      await repo.transition(session.id, to);
    }
    await repo.finish(session.id, SessionOutcome.completed,
        feeling: SessionFeeling.good);

    final done = await db.select(db.focusSessions).getSingle();
    expect(done.state, SessionState.completed);
    expect(done.outcome, SessionOutcome.completed);
    expect(done.feeling, SessionFeeling.good);
    expect(done.endedAt, isNotNull);
    expect(done.events.map((e) => e.toState), [
      SessionState.awaitingScan,
      SessionState.activating,
      SessionState.active,
      SessionState.releasing,
      SessionState.completed,
    ]);
    expect(done.events.first.fromState, SessionState.selecting);
    final times = done.events.map((e) => e.at).toList();
    expect([...times]..sort(), times);
    expect(await repo.findOpen(), isNull);
  });

  test('illegale overgang gooit en verandert niets', () async {
    final session = await startSession(repo);
    final before = await db.select(db.focusSessions).getSingle();
    clock.advance();
    await expectLater(
      repo.transition(session.id, SessionState.active),
      throwsA(isA<IllegalTransition>()),
    );
    await expectLater(
      repo.transition(session.id, SessionState.completed),
      throwsA(isA<IllegalTransition>()),
    );
    final after = await db.select(db.focusSessions).getSingle();
    expect(after.state, before.state);
    expect(after.events, isEmpty);
    expect(after.updatedAt, before.updatedAt);
  });

  test('elke overgang uit de tabel wordt gehandhaafd', () async {
    for (final from in SessionState.values) {
      for (final to in SessionState.values) {
        final allowed = sessionTransitions[from]?.contains(to) ?? false;
        if (from == SessionState.completed || from == SessionState.unknown) {
          expect(allowed, isFalse);
        }
        if (to == SessionState.selecting) expect(allowed, isFalse);
      }
    }
    expect(sessionTransitions[SessionState.active],
        contains(SessionState.emergency));
    expect(sessionTransitions[SessionState.emergency],
        {SessionState.releasing});
  });

  test('markBlockingConfirmed werkt alleen vanuit activating', () async {
    final session = await startSession(repo);
    await expectLater(
      repo.markBlockingConfirmed(session.id),
      throwsA(isA<IllegalTransition>()),
    );
    await repo.transition(session.id, SessionState.awaitingScan);
    await expectLater(
      repo.markBlockingConfirmed(session.id),
      throwsA(isA<IllegalTransition>()),
    );
    expect((await repo.findOpen())!.blockingConfirmedAt, isNull);

    await repo.transition(session.id, SessionState.activating);
    await repo.markBlockingConfirmed(session.id);
    expect((await repo.findOpen())!.blockingConfirmedAt, isNotNull);

    await repo.transition(session.id, SessionState.active);
    await expectLater(
      repo.markBlockingConfirmed(session.id),
      throwsA(isA<IllegalTransition>()),
    );
  });

  test('mislukte activatie eindigt in completed met foutcode', () async {
    final session = await startSession(repo, upTo: SessionState.activating);
    await repo.finish(session.id, SessionOutcome.activationFailed,
        errorCode: 'permission_denied');
    final row = await db.select(db.focusSessions).getSingle();
    expect(row.outcome, SessionOutcome.activationFailed);
    expect(row.blockingConfirmedAt, isNull);
    expect(row.events.last.errorCode, 'permission_denied');
  });

  test('noodstop loopt via emergency naar releasing', () async {
    final session = await startSession(repo, upTo: SessionState.active);
    await repo.transition(session.id, SessionState.emergency);
    await repo.transition(session.id, SessionState.releasing);
    await repo.markBlockingReleased(session.id);
    await repo.finish(session.id, SessionOutcome.emergencyRelease);
    final row = await db.select(db.focusSessions).getSingle();
    expect(row.outcome, SessionOutcome.emergencyRelease);
    expect(row.blockingReleasedAt, isNotNull);
  });

  test('tweede start faalt zolang er een sessie open is', () async {
    final first = await startSession(repo);
    await expectLater(
      repo.start(
        mode: 'focus',
        source: SessionSource.manual,
        platform: SessionPlatform.android,
      ),
      throwsA(isA<SessionAlreadyOpenError>()),
    );
    await repo.finish(first.id, SessionOutcome.cancelled);
    await repo.start(
      mode: 'focus',
      source: SessionSource.manual,
      platform: SessionPlatform.android,
    );
  });

  test('de database dwingt een open sessie ook zelf af', () async {
    await startSession(repo);
    await expectLater(
      db.into(db.focusSessions).insert(FocusSessionsCompanion.insert(
            mode: 'focus',
            source: SessionSource.manual,
            platform: SessionPlatform.android,
            state: SessionState.selecting,
            startedAt: clock.current.toUtc(),
            localDate: '2026-03-02',
            updatedAt: clock.current.toUtc(),
          )),
      throwsA(isA<Exception>()),
    );
  });

  test('local_date is de lokale datum, ook om 23:50', () async {
    clock.current = DateTime(2026, 3, 2, 23, 50);
    final session = await startSession(repo);
    expect(session.localDate, '2026-03-02');
    expect(session.startedAt.isUtc, isTrue);
  });

  test('geschiedenis toont alleen afgeronde sessies, nieuwste eerst', () async {
    final a = await startSession(repo);
    await repo.finish(a.id, SessionOutcome.cancelled);
    clock.advance(const Duration(hours: 1));
    final b = await startSession(repo);
    await repo.finish(b.id, SessionOutcome.completed);
    clock.advance(const Duration(hours: 1));
    await startSession(repo);

    final history = await repo.watchHistory(limit: 10).first;
    expect(history.map((s) => s.id), [b.id, a.id]);
    expect(await repo.watchHistory(limit: 1).first, hasLength(1));
    expect(await repo.watchOpen().first, isNotNull);
  });

  test('findOpen vindt de sessie na heropenen van de database', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final dir = await Directory.systemTemp.createTemp('rfm_db_test');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/test.sqlite');

    final first = AppDatabase(NativeDatabase(file));
    final started = await startSession(
      FocusSessionRepository(first, now: clock.call),
      upTo: SessionState.active,
    );
    await first.close();

    final second = AppDatabase(NativeDatabase(file));
    addTearDown(second.close);
    final found = await FocusSessionRepository(second).findOpen();
    expect(found?.id, started.id);
    expect(found?.state, SessionState.active);
    expect(found?.events, hasLength(3));
  });

  test('routine hard verwijderen zet routine_id op null en houdt de sessie',
      () async {
    final routines = RoutineRepository(db, now: clock.call);
    final routine = await routines.create(mode: 'focus', name: 'Avond');
    final session = await repo.start(
      mode: 'focus',
      source: SessionSource.schedule,
      platform: SessionPlatform.android,
      routineId: routine.id,
    );
    expect(session.routineId, routine.id);

    await db.delete(db.routines).go();

    final row = await db.select(db.focusSessions).getSingle();
    expect(row.id, session.id);
    expect(row.routineId, isNull);
  });

  test('onbekende sessie geeft RowNotFoundError', () async {
    await expectLater(
      repo.transition('bestaat-niet', SessionState.awaitingScan),
      throwsA(isA<RowNotFoundError>()),
    );
  });
}
