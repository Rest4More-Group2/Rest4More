import 'dart:convert';
import 'dart:typed_data';

import '../database/app_database.dart';
import 'cloud_data_service.dart';
import 'sync_scheduler.dart';

/// Uitkomst van [LocalDataService.wipeEverything].
class WipeResult {
  const WipeResult({required this.cloudErasurePending});

  /// De cloudgegevens konden niet meteen gewist worden (bijvoorbeeld zonder
  /// verbinding). Dat wordt bij het volgende openen van de app afgemaakt.
  final bool cloudErasurePending;
}

/// Recht op inzage en wissen voor alles wat op dit toestel staat.
class LocalDataService {
  LocalDataService(this._db, this._cloud, this._state);

  final AppDatabase _db;
  final CloudDataService _cloud;
  final SyncStateStore _state;

  /// Kinderen eerst, zodat verwijzingen het wissen niet blokkeren.
  static const _tablesChildrenFirst = [
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

  /// Alle lokale gegevens als leesbare json. Waarden staan zoals ze zijn
  /// opgeslagen: tijden als UTC-tekst, true en false als 1 en 0, en de iOS
  /// selectie als base64.
  Future<String> exportAsJson() async {
    final data = <String, Object?>{
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'schema_version': _db.schemaVersion,
    };
    for (final table in _tablesChildrenFirst.reversed) {
      final rows = await _db.customSelect('SELECT * FROM $table').get();
      data[table] = [
        for (final row in rows)
          {
            for (final entry in row.data.entries)
              entry.key: entry.value is Uint8List
                  ? base64Encode(entry.value as Uint8List)
                  : entry.value,
          },
      ];
    }
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Wist alles op dit toestel en, als er een cloudaccount is, ook de cloud.
  ///
  /// De cloud gaat eerst: toestemming wordt ingetrokken en de server gewist. Lukt
  /// dat niet, dan wordt het lokale wissen toch uitgevoerd en blijft de
  /// verwijdering in de cloud openstaan. Daarna worden alle tabellen leeg
  /// gemaakt en wordt het bestand opgeschoond.
  Future<WipeResult> wipeEverything() async {
    try {
      await _cloud.withdrawConsent();
    } on Exception {
      // Blijft openstaan, zie hieronder.
    }

    await _db.transaction(() async {
      for (final table in _tablesChildrenFirst) {
        await _db.customStatement('DELETE FROM $table');
      }
    });
    // Geef de vrijgekomen ruimte terug, zodat verwijderde gegevens niet in het
    // bestand blijven staan.
    await _db.customStatement('VACUUM');
    await _state.clear();

    final pending = await _state.lastUserId() != null;
    return WipeResult(cloudErasurePending: pending);
  }
}
