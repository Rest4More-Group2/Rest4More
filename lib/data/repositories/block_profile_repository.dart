import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/converters.dart';
import '../database/enums.dart';
import 'repository_support.dart';

class BlockProfileRepository {
  BlockProfileRepository(this._db, {this._now = DateTime.now});

  final AppDatabase _db;
  final Clock _now;

  DateTime get _stamp => _now().toUtc();

  Stream<List<BlockProfile>> watchAll() => (_db.select(_db.blockProfiles)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.name), (t) => OrderingTerm.asc(t.id)]))
      .watch();

  Future<BlockProfile> create({
    required String name,
    BlockContext? context,
    List<BlockItemData> items = const [],
  }) {
    return _db.into(_db.blockProfiles).insertReturning(
          BlockProfilesCompanion.insert(
            name: name,
            updatedAt: _stamp,
            context: Value(context),
            items: Value(items),
          ),
        );
  }

  Future<void> _write(String id, BlockProfilesCompanion changes) async {
    final rows = await (_db.update(_db.blockProfiles)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .write(changes.copyWith(
      updatedAt: Value(_stamp),
      dirty: const Value(true),
    ));
    if (rows == 0) throw RowNotFoundError('block_profiles', id);
  }

  Future<void> update(String id, {String? name, BlockContext? context}) =>
      _write(
        id,
        BlockProfilesCompanion(
          name: Value.absentIfNull(name),
          context: Value.absentIfNull(context),
        ),
      );

  /// Verwijdert zacht. De lokale iOS-selectie hoort erbij en verdwijnt mee.
  Future<void> softDelete(String id) {
    return _db.transaction(() async {
      await _write(id, BlockProfilesCompanion(deletedAt: Value(_stamp)));
      await (_db.delete(_db.iosSelections)
            ..where((t) => t.blockProfileId.equals(id)))
          .go();
    });
  }

  Future<void> setItems(String id, List<BlockItemData> items) =>
      _write(id, BlockProfilesCompanion(items: Value(items)));
}

/// Alleen lokaal: de opake iOS-selectie per blokkeerprofiel.
class IosSelectionStore {
  IosSelectionStore(this._db);

  final AppDatabase _db;

  Future<void> save(String blockProfileId, Uint8List blob) =>
      _db.into(_db.iosSelections).insertOnConflictUpdate(
            IosSelectionsCompanion.insert(
              blockProfileId: blockProfileId,
              selectionBlob: blob,
            ),
          );

  Future<Uint8List?> get(String blockProfileId) async {
    final row = await (_db.select(_db.iosSelections)
          ..where((t) => t.blockProfileId.equals(blockProfileId)))
        .getSingleOrNull();
    return row?.selectionBlob;
  }

  Future<void> delete(String blockProfileId) => (_db.delete(_db.iosSelections)
        ..where((t) => t.blockProfileId.equals(blockProfileId)))
      .go();
}
