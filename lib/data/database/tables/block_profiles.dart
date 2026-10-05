import 'package:drift/drift.dart';

import '../converters.dart';
import '../enums.dart';
import '../sync_columns.dart';

/// Een set apps en sites die geblokkeerd of toegestaan zijn.
class BlockProfiles extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get context => text()
      .map(const DbEnumConverter(BlockContext.values, BlockContext.unknown))
      .nullable()();

  /// Lijst van [BlockItemData] als json.
  TextColumn get items => text()
      .map(const BlockItemsConverter())
      .withDefault(const Constant('[]'))();
}
