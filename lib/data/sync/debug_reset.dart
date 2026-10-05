import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import 'sync_scheduler.dart';

/// Tabellen, kinderen eerst, zodat verwijzingen het wissen niet blokkeren.
const _tablesChildrenFirst = [
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

/// Maakt de lokale database leeg en vergeet de synchronisatiestand, zodat de
/// app opnieuw begint bij de onboarding. Alleen voor debugbuilds, via
/// `--dart-define=DEBUG_RESET=true`.
///
/// De cloud blijft ongemoeid en er wordt niets ingetrokken: het account-id
/// wordt vergeten, zodat dit niet als "openstaande verwijdering" telt. Voor
/// echt wissen, ook in de cloud, bestaat `LocalDataService.wipeEverything`.
Future<void> resetLocalData(AppDatabase db, SyncStateStore state) async {
  await db.transaction(() async {
    for (final table in _tablesChildrenFirst) {
      await db.customStatement('DELETE FROM $table');
    }
  });
  await state.clear();
  await state.clearUserId();
  if (kDebugMode) debugPrint('[reset] lokale database leeggemaakt');
}
