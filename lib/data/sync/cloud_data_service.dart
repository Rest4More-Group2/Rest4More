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

  /// Trekt de toestemming voor synchronisatie in en wist daarna de cloudgegevens.
  /// Is de server niet te bereiken, dan blijft de verwijdering openstaan en
  /// wordt die bij het volgende openen van de app (of na het opnieuw proberen)
  /// afgemaakt. Gegevens in de cloud blijven dus nooit onbeperkt staan na
  /// intrekken.
  Future<void> withdrawConsent() async {
    await _profiles.recordCloudSyncConsent(null);
    try {
      await completePendingErasure();
    } on Exception {
      // Blijft openstaan, zie [completePendingErasure].
    }
  }

  /// Maakt een openstaande verwijdering af. Die is er als er geen toestemming
  /// meer is terwijl er nog een serveraccount bekend is, bijvoorbeeld na
  /// intrekken, een leeftijd onder 16, of een mislukte eerdere poging. Geeft
  /// terug of er iets is gewist. Gooit als de server niet bereikbaar is, de
  /// verwijdering blijft dan openstaan.
  Future<bool> completePendingErasure() async {
    if (_remote is UnavailableSyncRemote) return false;
    if ((await _profiles.get()).cloudSyncConsentAt != null) return false;
    if (await _state.lastUserId() == null) return false;

    if (_remote.currentUserId == null) {
      // Het account bestaat niet meer (bijvoorbeeld opgeruimd), er is niets
      // meer te wissen.
      await _resetAfterErasure();
    } else {
      await deleteCloudData();
    }
    return true;
  }

  /// Wist alles in de cloud en zet synchronisatie uit. De lokale gegevens
  /// blijven staan: ze worden opnieuw als te versturen gemarkeerd, zodat ze
  /// bij nieuwe toestemming opnieuw naar een nieuw account kunnen. Mislukt
  /// het wissen op de server, dan verandert er lokaal niets.
  Future<void> deleteCloudData() async {
    await _remote.deleteMyData();
    await _resetAfterErasure();
  }

  Future<void> _resetAfterErasure() async {
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
    if ((await _profiles.get()).cloudSyncConsentAt != null) {
      await _profiles.recordCloudSyncConsent(null);
    }
    await _state.clear();
    await _state.clearUserId();
  }
}
