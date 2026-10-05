import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../repositories/profile_repository.dart';
import 'sync_remote.dart';
import 'sync_scheduler.dart';

/// Rechten van de gebruiker over de cloudkopie: inzage en verwijdering.
class CloudDataService {
  CloudDataService(this._db, this._remote, this._state, this._profiles);

  final AppDatabase _db;
  final SyncRemote _remote;
  final SyncStateStore _state;
  final ProfileRepository _profiles;

  static const _syncedTables = [
    'profiles',
    'consent_records',
    'block_profiles',
    'routines',
    'accessories',
    'focus_sessions',
    'programme_enrollments',
    'programme_days',
  ];

  /// Alle cloudgegevens als leesbare json, klaar om op te slaan of te delen.
  Future<String> exportAsJson() async {
    await _remote.ensureSignedIn();
    final data = await _remote.exportMyData();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Wist alles in de cloud en zet synchronisatie uit. De lokale gegevens
  /// blijven staan: ze worden opnieuw als te versturen gemarkeerd, zodat ze
  /// bij nieuwe toestemming opnieuw naar een nieuw account kunnen. Mislukt
  /// het wissen op de server, dan verandert er lokaal niets.
  Future<void> deleteCloudData() async {
    await _remote.deleteMyData();

    await _db.transaction(() async {
      for (final table in _syncedTables) {
        await _db.customUpdate(
          'UPDATE $table SET dirty = 1',
          updates: _db.allTables.where((t) => t.actualTableName == table).toSet(),
          updateKind: UpdateKind.update,
        );
      }
      // Rechten komen van de server en horen bij het verwijderde account.
      await _db.delete(_db.entitlements).go();
    });
    await _profiles.recordCloudSyncConsent(null);
    await _state.clear();
  }
}
