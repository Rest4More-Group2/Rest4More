import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/data/sync/debug_seed.dart';
import 'package:rest4more/data/sync/sync_engine.dart';

import 'sync_engine_test.dart' show FakeRemote;
import 'test_support.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  test('voorbeelddata vult elke tabel en gaat in een keer naar de server',
      () async {
    await ProfileRepository(db).recordCloudSyncConsent(DateTime.now());
    expect(await seedDebugData(db), isTrue);

    final remote = FakeRemote();
    final result = await SyncEngine(db, remote).pushDirty();
    expect(result.ok, isTrue);
    expect(remote.tables, [
      'profiles',
      'block_profiles',
      'routines',
      'accessories',
      'focus_sessions',
      'programme_enrollments',
      'programme_days',
    ]);
    expect(remote.rowsOf('programme_days'), hasLength(14));

    final session = remote.rowsOf('focus_sessions').single;
    expect(session['state'], 'completed');
    expect(session['blocking_confirmed_at'], isNotNull);
    expect((session['events'] as List), hasLength(5));
    final routine = remote.rowsOf('routines').single;
    expect(routine['days_mask'], 31);
    expect((routine['steps'] as List), hasLength(2));
    expect(remote.rowsOf('block_profiles').single['items'], hasLength(2));
    final day = remote.rowsOf('programme_days').firstWhere(
          (d) => d['day_number'] == 1,
        );
    expect(day['rested_score'], 4);
    expect(day['status'], 'completed');
  });

  test('tweede keer maakt geen dubbele rijen', () async {
    expect(await seedDebugData(db), isTrue);
    expect(await seedDebugData(db), isFalse);
    expect(await db.select(db.routines).get(), hasLength(1));
    expect(await db.select(db.programmeDays).get(), hasLength(14));
  });
}
