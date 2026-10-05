import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/intake/intake_service.dart';
import 'package:rest4more/data/programme/content_catalog.dart';
import 'package:rest4more/data/programme/plan_service.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/data/sync/debug_reset.dart';
import 'package:rest4more/data/sync/debug_seed.dart';

import 'sync_scheduler_test.dart' show MemoryStateStore;
import 'test_support.dart';

void main() {
  late AppDatabase db;
  late MemoryStateStore state;

  setUp(() {
    db = memoryDb();
    state = MemoryStateStore();
  });
  tearDown(() => db.close());

  Future<int> count(String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle())
          .read<int>('c');

  test('alle tabellen zijn daarna leeg', () async {
    await seedDebugData(db);
    await grantConsent(db);
    await db.customStatement(
        "INSERT INTO sync_cursors (target_table, cursor) VALUES ('routines', 'x')");
    for (final table in ['profiles', 'routines', 'programme_days', 'consent_records']) {
      expect(await count(table), greaterThan(0), reason: table);
    }

    await resetLocalData(db, state);

    for (final table in [
      'profiles',
      'consent_records',
      'block_profiles',
      'routines',
      'accessories',
      'focus_sessions',
      'programme_enrollments',
      'programme_days',
      'local_notifications',
      'ios_selections',
      'entitlements',
      'sync_cursors',
    ]) {
      expect(await count(table), 0, reason: table);
    }
  });

  test('de synchronisatiestand wordt vergeten', () async {
    state.date = '2026-03-02';
    state.userId = 'user-1';
    await resetLocalData(db, state);
    expect(state.date, isNull);
    expect(state.userId, isNull);
  });

  test('daarna begint de onboarding weer bij het begin en kan een plan weer', () async {
    final intake = IntakeService(ProfileRepository(db));
    await intake.saveGoal(1);
    await intake.complete(reminderEnabled: false);
    await resetLocalData(db, state);

    final progress = await intake.load();
    expect(progress.step, OnboardingStep.welcome);
    expect(progress.completed, isFalse);

    await intake.saveGoal(0);
    await intake.complete(reminderEnabled: false);
    final plans = PlanService(db, () async => ContentCatalog.parse(
        await Future.value(_content)));
    expect(await plans.ensurePlan(), isTrue);
  });

  test('een lege database resetten geeft geen fout', () async {
    await resetLocalData(db, state);
    await resetLocalData(db, state);
    expect(await count('profiles'), 0);
  });
}

final _content = '''{"version":"t","goals":{"phone":"Put phone away earlier","routine":"Build a routine","social":"Use less social media"},
"obstacle_actions":{"scrolling":"a","availability":"a","thoughts":"a","planning":"a","alarm":"a","no_routine":"a"},
"days":[${[for (final g in ['phone', 'routine', 'social']) for (var i = 1; i <= 14; i++) '{"content_id":"c$g$i","day":$i,"goal":"$g","title":"t","explanation":"e","action":"a","smaller_action":"s"}'].join(',')}]}''';
