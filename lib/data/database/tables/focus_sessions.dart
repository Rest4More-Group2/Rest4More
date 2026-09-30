import 'package:drift/drift.dart';

import '../converters.dart';
import '../enums.dart';
import '../sync_columns.dart';
import 'accessories.dart';
import 'block_profiles.dart';
import 'routines.dart';

/// Een focussessie. De geschiedenis blijft bestaan als een routine, profiel
/// of accessoire wordt verwijderd.
@TableIndex(name: 'focus_sessions_started_at', columns: {#startedAt})
class FocusSessions extends Table with SyncColumns {
  TextColumn get routineId => text()
      .nullable()
      .references(Routines, #id, onDelete: KeyAction.setNull)();
  TextColumn get blockProfileId => text()
      .nullable()
      .references(BlockProfiles, #id, onDelete: KeyAction.setNull)();
  TextColumn get accessoryId => text()
      .nullable()
      .references(Accessories, #id, onDelete: KeyAction.setNull)();
  TextColumn get mode => text()();
  TextColumn get source => text()
      .map(const DbEnumConverter(SessionSource.values, SessionSource.unknown))();
  TextColumn get platform => text().map(
      const DbEnumConverter(SessionPlatform.values, SessionPlatform.unknown))();
  TextColumn get state => text()
      .map(const DbEnumConverter(SessionState.values, SessionState.unknown))();
  DateTimeColumn get startedAt => dateTime()();

  /// Lokale kalenderdatum van `startedAt`, als `YYYY-MM-DD`.
  TextColumn get localDate => text()();
  IntColumn get plannedSeconds => integer().nullable()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get outcome => text()
      .map(const DbEnumConverter(SessionOutcome.values, SessionOutcome.unknown))
      .nullable()();

  /// Alleen gezet als blokkeren aantoonbaar is gelukt.
  DateTimeColumn get blockingConfirmedAt => dateTime().nullable()();
  DateTimeColumn get blockingReleasedAt => dateTime().nullable()();
  TextColumn get feeling => text()
      .map(const DbEnumConverter(SessionFeeling.values, SessionFeeling.unknown))
      .nullable()();

  /// Lijst van [SessionEventData] als json.
  TextColumn get events => text()
      .map(const SessionEventsConverter())
      .withDefault(const Constant('[]'))();
}
