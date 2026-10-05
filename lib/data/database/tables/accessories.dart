import 'package:drift/drift.dart';

import '../converters.dart';
import '../enums.dart';
import '../sync_columns.dart';

/// Een kaart of ander hulpstuk. Alleen de hash van de NFC-token wordt
/// bewaard, nooit de ruwe waarde.
@DataClassName('Accessory')
class Accessories extends Table with SyncColumns {
  TextColumn get kind => text()
      .map(const DbEnumConverter(AccessoryKind.values, AccessoryKind.unknown))();
  TextColumn get tokenHash => text().nullable().unique()();
  TextColumn get label => text()();
  TextColumn get status => text()
      .map(const DbEnumConverter(
          AccessoryStatus.values, AccessoryStatus.unknown))
      .withDefault(const Constant('active'))();
  DateTimeColumn get pairedAt => dateTime().nullable()();
}
