import 'package:drift/drift.dart';

import 'block_profiles.dart';

/// Alleen lokaal: de iOS-selectie is een opaak blok dat niet naar de server
/// gaat. Geen synckolommen.
class IosSelections extends Table {
  TextColumn get blockProfileId =>
      text().references(BlockProfiles, #id, onDelete: KeyAction.cascade)();
  BlobColumn get selectionBlob => blob()();

  @override
  Set<Column> get primaryKey => {blockProfileId};
}
