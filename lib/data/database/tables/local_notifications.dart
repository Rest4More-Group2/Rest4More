import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../converters.dart';
import '../enums.dart';
import 'programme_days.dart';
import 'routines.dart';

/// Alleen lokaal: geplande meldingen van het besturingssysteem. Geen
/// synckolommen.
@DataClassName('LocalNotification')
class LocalNotifications extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get programmeDayId => text()
      .nullable()
      .references(ProgrammeDays, #id, onDelete: KeyAction.cascade)();
  TextColumn get routineId => text()
      .nullable()
      .references(Routines, #id, onDelete: KeyAction.cascade)();
  IntColumn get osNotificationId => integer()();
  TextColumn get kind => text().map(
      const DbEnumConverter(NotificationKind.values, NotificationKind.unknown))();

  /// Lokale kalenderdatum, `YYYY-MM-DD`.
  TextColumn get firesOn => text()();

  /// Minuten sinds middernacht (0 tot 1439).
  IntColumn get firesAtMinutes => integer()();
  TextColumn get status => text()
      .map(const DbEnumConverter(
          NotificationStatus.values, NotificationStatus.unknown))
      .withDefault(const Constant('scheduled'))();

  @override
  Set<Column> get primaryKey => {id};
}
