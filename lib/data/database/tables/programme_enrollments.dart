import 'package:drift/drift.dart';

import '../converters.dart';
import '../enums.dart';
import '../sync_columns.dart';
import 'profiles.dart';

/// Deelname aan het programma van 14 dagen.
class ProgrammeEnrollments extends Table with SyncColumns {
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get contentVersion => text()();
  TextColumn get status => text()
      .map(const DbEnumConverter(
          EnrollmentStatus.values, EnrollmentStatus.unknown))
      .withDefault(const Constant('active'))();

  /// Lokale kalenderdatum, `YYYY-MM-DD`.
  TextColumn get startedOn => text()();

  /// Intake-antwoorden bij de start, ongetypeerd.
  TextColumn get selection => text()
      .map(const JsonMapConverter())
      .withDefault(const Constant('{}'))();
  TextColumn get direction => text()
      .map(const DbEnumConverter(
          ProgrammeDirection.values, ProgrammeDirection.unknown))
      .nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}
