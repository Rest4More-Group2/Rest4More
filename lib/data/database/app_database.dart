import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// De lokale database is de bron van waarheid voor gebruikersdata.
///
/// Maak nooit zelf een tweede instantie aan buiten `databaseProvider`: dat
/// opent een tweede verbinding met hetzelfde bestand.
@DriftDatabase(tables: [])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'restformore'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Gewoonte bij elke schemawijziging: verhoog `schemaVersion`, voeg
          // precies een stap toe voor die versie, en maak een nieuwe dump met
          // `dart run drift_dev schema dump lib/data/database/app_database.dart
          // drift_schemas/`. Oude dumps blijven staan voor de migratietests.
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
