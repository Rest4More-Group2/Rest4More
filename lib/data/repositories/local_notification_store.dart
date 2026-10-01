import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/enums.dart';
import '../database/local_types.dart';
import 'repository_support.dart';

/// Een geplande melding die de opslag moet bewaren.
class PlannedEntry {
  const PlannedEntry({
    required this.osNotificationId,
    required this.kind,
    required this.firesOn,
    required this.firesAtMinutes,
    this.programmeDayId,
    this.routineId,
  });

  final int osNotificationId;
  final NotificationKind kind;

  /// Lokale kalenderdatum.
  final DateTime firesOn;
  final int firesAtMinutes;
  final String? programmeDayId;
  final String? routineId;
}

/// Alleen lokaal: bewaart welke meldingen gepland staan. Plant zelf niets bij
/// het besturingssysteem.
class LocalNotificationStore {
  LocalNotificationStore(this._db);

  final AppDatabase _db;

  /// Vervangt alle rijen door de nieuwe planning, in een transactie.
  Future<void> replaceAll(List<PlannedEntry> entries) async {
    for (final entry in entries) {
      checkedMinutes(entry.firesAtMinutes, 'firesAtMinutes');
    }
    await _db.transaction(() async {
      await _db.delete(_db.localNotifications).go();
      await _db.batch((batch) {
        batch.insertAll(_db.localNotifications, [
          for (final entry in entries)
            LocalNotificationsCompanion.insert(
              osNotificationId: entry.osNotificationId,
              kind: entry.kind,
              firesOn: LocalDate.format(entry.firesOn),
              firesAtMinutes: entry.firesAtMinutes,
              programmeDayId: Value(entry.programmeDayId),
              routineId: Value(entry.routineId),
            ),
        ]);
      });
    });
  }

  Future<void> cancelAll() => (_db.update(_db.localNotifications)
        ..where((t) => t.status.equals(NotificationStatus.scheduled.id)))
      .write(const LocalNotificationsCompanion(
    status: Value(NotificationStatus.cancelled),
  ));

  Future<void> markOpened(String id) => (_db.update(_db.localNotifications)
        ..where((t) => t.id.equals(id)))
      .write(const LocalNotificationsCompanion(
    status: Value(NotificationStatus.opened),
  ));

  Stream<List<LocalNotification>> watchScheduled() =>
      (_db.select(_db.localNotifications)
            ..where((t) => t.status.equals(NotificationStatus.scheduled.id))
            ..orderBy([
              (t) => OrderingTerm.asc(t.firesOn),
              (t) => OrderingTerm.asc(t.firesAtMinutes),
            ]))
          .watch();
}
