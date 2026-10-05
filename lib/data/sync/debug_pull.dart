import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_providers.dart';
import '../../providers/sync_providers.dart';
import 'sync_remote.dart';
import 'sync_scheduler.dart';

/// Probeert de pull op de echte server. Alleen voor debugbuilds.
///
/// Maakt alle lokale gegevens leeg (de cloud blijft ongemoeid), vergeet de
/// voortgang en het account-id zoals na een opnieuw aangemaakte database, en
/// haalt dan alles terug van de server. Logt alleen aantallen.
Future<void> runDebugPull(ProviderContainer container) async {
  void log(String message) => debugPrint('[pull] $message');

  final remote = container.read(syncRemoteProvider);
  if (remote is UnavailableSyncRemote) {
    log('uit: geen Supabase');
    return;
  }
  if (remote.currentUserId == null) {
    log('uit: geen sessie. Draai eerst eens met DEBUG_SYNC=true zodat er een '
        'account en data in de cloud staat.');
    return;
  }

  final db = container.read(databaseProvider);
  const tables = [
    'sync_cursors',
    'local_notifications',
    'ios_selections',
    'programme_days',
    'programme_enrollments',
    'focus_sessions',
    'routines',
    'accessories',
    'block_profiles',
    'consent_records',
    'entitlements',
    'profiles',
  ];

  Future<Map<String, int>> counts() async => {
        for (final t in tables)
          if (t != 'sync_cursors')
            t: (await db.customSelect('SELECT COUNT(*) AS c FROM $t').getSingle())
                .read<int>('c'),
      };

  log('lokaal voor: ${await counts()}');
  await db.transaction(() async {
    for (final t in tables) {
      await db.customStatement('DELETE FROM $t');
    }
  });
  final state = PreferencesSyncStateStore();
  await state.clearUserId();
  await state.clear();
  log('lokaal leeggemaakt (cloud niet aangeraakt)');

  final result = await container.read(pullEngineProvider).pull();
  log('pull ok=${result.ok} applied=${result.applied} skipped=${result.skipped} '
      'conflicts=${result.conflicts.length} error=${result.error}');
  log('lokaal na: ${await counts()}');
}
