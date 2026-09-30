import 'package:drift/drift.dart';

import '../converters.dart';
import '../enums.dart';
import '../sync_columns.dart';

/// Precies een profielrij per toestel. Alle intake-antwoorden zijn optioneel,
/// zodat een onderbroken intake kan hervatten via `intakeStep`.
class Profiles extends Table with SyncColumns {
  TextColumn get displayName => text().nullable()();
  TextColumn get ageBand => text()
      .map(const DbEnumConverter(AgeBand.values, AgeBand.unknown))
      .nullable()();
  TextColumn get primaryGoal => text()
      .map(const DbEnumConverter(PrimaryGoal.values, PrimaryGoal.unknown))
      .nullable()();
  TextColumn get obstacle => text()
      .map(const DbEnumConverter(Obstacle.values, Obstacle.unknown))
      .nullable()();
  TextColumn get rhythm => text()
      .map(const DbEnumConverter(Rhythm.values, Rhythm.unknown))
      .nullable()();
  IntColumn get putawayMinutes => integer().nullable()();
  TextColumn get stepSize => text()
      .map(const DbEnumConverter(StepSize.values, StepSize.unknown))
      .nullable()();
  TextColumn get preferredActivity => text()
      .map(const DbEnumConverter(
          PreferredActivity.values, PreferredActivity.unknown))
      .nullable()();
  TextColumn get anchorText => text().nullable()();
  TextColumn get activityMaterial => text().nullable()();
  BoolColumn get ownsRestnest => boolean().withDefault(const Constant(false))();
  BoolColumn get ownsCard => boolean().withDefault(const Constant(false))();

  /// Minuten sinds middernacht (0 tot 1439).
  IntColumn get bedtimeMinutes => integer().nullable()();
  IntColumn get phoneAwayMinutes => integer().nullable()();
  TextColumn get timezone => text().withDefault(const Constant('UTC'))();
  BoolColumn get notifyProgramme =>
      boolean().withDefault(const Constant(false))();

  /// Minuten sinds middernacht (0 tot 1439).
  IntColumn get notifyTimeMinutes => integer().nullable()();
  DateTimeColumn get cloudSyncConsentAt => dateTime().nullable()();
  IntColumn get intakeStep => integer().withDefault(const Constant(0))();
  DateTimeColumn get intakeCompletedAt => dateTime().nullable()();
}
