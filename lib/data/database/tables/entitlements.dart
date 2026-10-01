import 'package:drift/drift.dart';

import '../converters.dart';
import '../enums.dart';
import '../sync_columns.dart';

/// Rechten op functies. Alleen de server schrijft hier, de app leest en
/// stuurt nooit terug. `feature` is bewust vrije tekst.
///
/// Let op: de latere push-lus voor synchronisatie moet deze tabel overslaan.
@DataClassName('Entitlement')
class Entitlements extends Table with SyncColumns {
  TextColumn get feature => text()();
  TextColumn get source => text().map(
      const DbEnumConverter(EntitlementSource.values, EntitlementSource.unknown))();
  TextColumn get status => text().map(
      const DbEnumConverter(EntitlementStatus.values, EntitlementStatus.unknown))();
  DateTimeColumn get startsAt => dateTime()();
  DateTimeColumn get endsAt => dateTime().nullable()();
}
