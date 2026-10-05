import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Beschrijft hoe een gesynchroniseerde tabel tussen lokaal en server wordt
/// omgezet. Gedeeld door push en pull.
class SyncTableSpec {
  const SyncTableSpec(
    this.name,
    this.table, {
    this.bools = const {},
    this.json = const {},
  });

  final String name;
  final TableInfo table;

  /// Booleankolommen, lokaal opgeslagen als 0 en 1.
  final Set<String> bools;

  /// Jsonb-kolommen met de waarde als de opgeslagen tekst onleesbaar is.
  final Map<String, Object?> json;
}

/// De gesynchroniseerde tabellen, ouders eerst: kinderen verwijzen naar hun
/// ouder, zowel op de server als lokaal. `entitlements` hoort er niet bij, die
/// is van de server.
List<SyncTableSpec> syncTableSpecs(AppDatabase db) => [
      SyncTableSpec('profiles', db.profiles,
          bools: {'owns_restnest', 'owns_card', 'notify_programme'}),
      SyncTableSpec('consent_records', db.consentRecords),
      SyncTableSpec('block_profiles', db.blockProfiles,
          json: {'items': <Object?>[]}),
      SyncTableSpec('routines', db.routines,
          bools: {'auto_start', 'enabled'}, json: {'steps': null}),
      SyncTableSpec('accessories', db.accessories),
      SyncTableSpec('focus_sessions', db.focusSessions,
          json: {'events': <Object?>[]}),
      SyncTableSpec('programme_enrollments', db.programmeEnrollments,
          json: {'selection': <String, Object?>{}}),
      SyncTableSpec('programme_days', db.programmeDays,
          json: {'snapshot': <String, Object?>{}}),
    ];
