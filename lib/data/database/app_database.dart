import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'converters.dart';
import 'encrypted_database.dart';
import 'enums.dart';
import 'tables/accessories.dart';
import 'tables/block_profiles.dart';
import 'tables/consent_records.dart';
import 'tables/entitlements.dart';
import 'tables/focus_sessions.dart';
import 'tables/ios_selections.dart';
import 'tables/local_notifications.dart';
import 'tables/profiles.dart';
import 'tables/programme_days.dart';
import 'tables/programme_enrollments.dart';
import 'tables/routines.dart';
import 'tables/sync_cursors.dart';

part 'app_database.g.dart';

/// De lokale database is de bron van waarheid voor gebruikersdata.
///
/// Maak nooit zelf een tweede instantie aan buiten `databaseProvider`: dat
/// opent een tweede verbinding met hetzelfde bestand.
@DriftDatabase(tables: [
  Profiles,
  Routines,
  BlockProfiles,
  IosSelections,
  Accessories,
  FocusSessions,
  ProgrammeEnrollments,
  ProgrammeDays,
  LocalNotifications,
  Entitlements,
  ConsentRecords,
  SyncCursors,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? openAppDatabase());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Gedeeltelijke unieke indexen kunnen niet in de Drift-DSL, daarom
          // hier met SQL. De database hoort bij een gebruiker, dus een
          // constante uitdrukking volstaat.
          await customStatement(
            'CREATE UNIQUE INDEX one_open_session ON focus_sessions ((1)) '
            'WHERE ended_at IS NULL AND deleted_at IS NULL',
          );
          await customStatement(
            'CREATE UNIQUE INDEX one_live_enrollment '
            'ON programme_enrollments ((1)) '
            "WHERE status IN ('active','paused') AND deleted_at IS NULL",
          );
        },
        onUpgrade: (m, from, to) async {
          // Gewoonte bij elke schemawijziging: verhoog `schemaVersion`, voeg
          // precies een stap toe voor die versie, en maak een nieuwe dump met
          // `flutter pub run drift_dev schema dump
          // lib/data/database/app_database.dart drift_schemas/`. Oude dumps
          // blijven staan voor de migratietests.
          if (from < 2) {
            // v2: bewijs van toestemming.
            await m.createTable(consentRecords);
          }
          if (from < 3) {
            // v3: voortgang van de pull per tabel.
            await m.createTable(syncCursors);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
