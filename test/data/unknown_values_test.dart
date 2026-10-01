import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/database/local_types.dart';
import 'package:rest4more/data/repositories/accessory_repository.dart';
import 'package:rest4more/data/repositories/block_profile_repository.dart';
import 'package:rest4more/data/repositories/focus_session_repository.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/data/repositories/programme_repository.dart';
import 'package:rest4more/data/repositories/routine_repository.dart';

import 'test_support.dart';

const _future = 'future_value';
const _ts = '2026-03-02T10:00:00.000Z';

void main() {
  late AppDatabase db;
  late TestClock clock;

  setUp(() {
    db = memoryDb();
    clock = TestClock();
  });
  tearDown(() => db.close());

  Future<String?> rawOf(String table, String column, String id) async {
    final rows = await db
        .customSelect("SELECT $column AS v FROM $table WHERE id = '$id'")
        .get();
    return rows.single.read<String?>('v');
  }

  test('profiel behoudt onbekende enumwaarden', () async {
    final repo = ProfileRepository(db, now: clock.call);
    final id = (await repo.get()).id;
    await db.customStatement('''UPDATE profiles SET age_band = '$_future',
      primary_goal = '$_future', obstacle = '$_future', rhythm = '$_future',
      step_size = '$_future', preferred_activity = '$_future' ''');
    await repo.upsert(const ProfileDraft(displayName: 'Sam'));
    await repo.saveIntakeStep(3);
    await repo.completeIntake();
    for (final c in [
      'age_band', 'primary_goal', 'obstacle', 'rhythm', 'step_size',
      'preferred_activity',
    ]) {
      expect(await rawOf('profiles', c, id), _future, reason: c);
    }
    expect(await rawOf('profiles', 'display_name', id), 'Sam');
  });

  test('routine behoudt onbekende end_rule', () async {
    final repo = RoutineRepository(db, now: clock.call);
    final id = (await repo.create(mode: 'focus', name: 'a')).id;
    await db.customStatement("UPDATE routines SET end_rule = '$_future'");
    await repo.update(id, name: 'b');
    await repo.setSteps(id, const []);
    await repo.setSchedule(id, WeekdayMask.none, 600, true);
    expect(await rawOf('routines', 'end_rule', id), _future);
    expect(await rawOf('routines', 'name', id), 'b');
  });

  test('blokkeerprofiel behoudt onbekende context', () async {
    final repo = BlockProfileRepository(db, now: clock.call);
    final id = (await repo.create(name: 'a')).id;
    await db.customStatement("UPDATE block_profiles SET context = '$_future'");
    await repo.update(id, name: 'b');
    await repo.setItems(id, const []);
    expect(await rawOf('block_profiles', 'context', id), _future);
  });

  test('accessoire behoudt onbekende kind', () async {
    final repo = AccessoryRepository(db, now: clock.call);
    final id = (await repo.pairCard(tokenHash: 'h', label: 'k')).id;
    await db.customStatement("UPDATE accessories SET kind = '$_future'");
    await repo.markLost(id);
    expect(await rawOf('accessories', 'kind', id), _future);
    expect(await rawOf('accessories', 'status', id), 'lost');
  });

  test('focussessie behoudt onbekende waarden en ruwe events', () async {
    final repo = FocusSessionRepository(db, now: clock.call);
    final id = (await startSession(repo, upTo: SessionState.active)).id;
    final events = '[{"at":"$_ts","event":"future_event","to_state":"x"},"kapot"]';
    await db.customStatement('''UPDATE focus_sessions SET source = '$_future',
      platform = '$_future', outcome = '$_future', feeling = '$_future',
      events = '$events' ''');
    await repo.transition(id, SessionState.releasing);
    await repo.markBlockingReleased(id);
    for (final c in ['source', 'platform', 'outcome', 'feeling']) {
      expect(await rawOf('focus_sessions', c, id), _future, reason: c);
    }
    final stored = await rawOf('focus_sessions', 'events', id);
    expect(stored, contains('future_event'));
    expect(stored, contains('"kapot"'));
    expect(stored, contains('"to_state":"releasing"'));
  });

  test('deelname behoudt onbekende direction', () async {
    final repo = ProgrammeRepository(db, now: clock.call);
    final id = await enrollWithDays(repo);
    await db.customStatement(
        "UPDATE programme_enrollments SET direction = '$_future'");
    await repo.pause(id);
    await repo.resume(id);
    expect(await rawOf('programme_enrollments', 'direction', id), _future);
  });

  test('programmadag behoudt onbekende waarden', () async {
    final repo = ProgrammeRepository(db, now: clock.call);
    final enrollmentId = await enrollWithDays(repo);
    final days = await repo.watchDays(enrollmentId).first;
    final a = days[0].id;
    final b = days[1].id;
    await db.customStatement('''UPDATE programme_days SET size = '$_future',
      fit = '$_future', blocker = '$_future', protected = '$_future' ''');
    await db.customStatement(
        "UPDATE programme_days SET status = '$_future' WHERE id = '$b'");

    await repo.markOpened(a);
    await repo.markOffered(b);
    await repo.setSize(b, DaySize.smaller);
    for (final c in ['fit', 'blocker', 'protected']) {
      expect(await rawOf('programme_days', c, a), _future, reason: c);
    }
    expect(await rawOf('programme_days', 'size', a), _future);
    expect(await rawOf('programme_days', 'status', a), 'opened');
    expect(await rawOf('programme_days', 'status', b), _future);
  });
}
