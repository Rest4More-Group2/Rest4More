import 'package:drift/drift.dart';

import '../converters.dart';
import '../enums.dart';
import '../sync_columns.dart';
import 'programme_enrollments.dart';

/// Een dag uit het programma. Zelfrapportage (`fit`, `blocker`, `protected`,
/// `restedScore`) is altijd optioneel.
@TableIndex(
  name: 'programme_days_enrollment_day',
  columns: {#enrollmentId, #dayNumber},
  unique: true,
)
@TableIndex(name: 'programme_days_scheduled_for', columns: {#scheduledFor})
class ProgrammeDays extends Table with SyncColumns {
  TextColumn get enrollmentId =>
      text().references(ProgrammeEnrollments, #id, onDelete: KeyAction.cascade)();
  IntColumn get dayNumber => integer()();
  TextColumn get contentId => text()();
  TextColumn get status => text()
      .map(const DbEnumConverter(DayStatus.values, DayStatus.unknown))
      .withDefault(const Constant('planned'))();
  TextColumn get size => text()
      .map(const DbEnumConverter(DaySize.values, DaySize.unknown))
      .withDefault(const Constant('standard'))();

  /// Lokale kalenderdatum, `YYYY-MM-DD`.
  TextColumn get scheduledFor => text()();
  DateTimeColumn get offeredAt => dateTime().nullable()();
  DateTimeColumn get openedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// De inhoud zoals de gebruiker die zag, ongetypeerd.
  TextColumn get snapshot => text()
      .map(const JsonMapConverter())
      .withDefault(const Constant('{}'))();
  TextColumn get fit => text()
      .map(const DbEnumConverter(DayFit.values, DayFit.unknown))
      .nullable()();
  TextColumn get blocker => text()
      .map(const DbEnumConverter(DayBlocker.values, DayBlocker.unknown))
      .nullable()();
  TextColumn get protected => text()
      .map(const DbEnumConverter(DayProtected.values, DayProtected.unknown))
      .nullable()();

  /// 1 tot en met 5.
  IntColumn get restedScore => integer().nullable()();
}
