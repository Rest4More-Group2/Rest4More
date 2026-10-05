import 'package:drift/drift.dart';

import '../converters.dart';
import '../enums.dart';
import '../sync_columns.dart';
import 'block_profiles.dart';

/// Een terugkerend rustmoment.
class Routines extends Table with SyncColumns {
  /// Verwijderen van het blokkeerprofiel wist de routine niet.
  TextColumn get blockProfileId => text()
      .nullable()
      .references(BlockProfiles, #id, onDelete: KeyAction.setNull)();

  /// Bewust gewone tekst: `RestMode.fromId` vangt onbekende waarden op (zoals
  /// de ingetrokken `sleep`). Hergebruik die id nooit.
  TextColumn get mode => text()();
  TextColumn get name => text()();
  TextColumn get endRule => text()
      .map(const DbEnumConverter(RoutineEndRule.values, RoutineEndRule.unknown))
      .withDefault(const Constant('manual'))();
  IntColumn get defaultMinutes => integer().nullable()();

  /// Weekdagen als bitmasker, zie `WeekdayMask`.
  IntColumn get daysMask => integer().withDefault(const Constant(0))();

  /// Minuten sinds middernacht (0 tot 1439).
  IntColumn get startMinutes => integer().nullable()();
  BoolColumn get autoStart => boolean().withDefault(const Constant(false))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// Lijst van [RoutineStepData] als json.
  TextColumn get steps => text().map(const RoutineStepsConverter()).nullable()();
}
