import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/enums.dart';
import 'repository_support.dart';

/// Er is al een accessoire met deze token-hash.
class DuplicateTokenHashError implements Exception {
  const DuplicateTokenHashError();

  @override
  String toString() => 'DuplicateTokenHashError';
}

class AccessoryRepository {
  AccessoryRepository(this._db, {this._now = DateTime.now});

  final AppDatabase _db;
  final Clock _now;

  DateTime get _stamp => _now().toUtc();

  /// SHA-256 van de ruwe token als hex. Zo komt de ruwe token nooit in de
  /// tabel.
  static String hashToken(String raw) =>
      sha256.convert(utf8.encode(raw)).toString();

  Stream<List<Accessory>> watchAll() => (_db.select(_db.accessories)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.label), (t) => OrderingTerm.asc(t.id)]))
      .watch();

  /// Koppelt een kaart. Een tweede kaart met dezelfde hash wordt geweigerd,
  /// ook als de eerste zacht is verwijderd.
  Future<Accessory> pairCard({
    required String tokenHash,
    required String label,
  }) {
    return _db.transaction(() async {
      final existing = await (_db.select(_db.accessories)
            ..where((t) => t.tokenHash.equals(tokenHash)))
          .getSingleOrNull();
      if (existing != null) throw const DuplicateTokenHashError();
      final now = _stamp;
      return _db.into(_db.accessories).insertReturning(
            AccessoriesCompanion.insert(
              kind: AccessoryKind.card,
              label: label,
              updatedAt: now,
              tokenHash: Value(tokenHash),
              pairedAt: Value(now),
            ),
          );
    });
  }

  Future<void> _setStatus(String id, AccessoryStatus status) async {
    final rows = await (_db.update(_db.accessories)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .write(AccessoriesCompanion(
      status: Value(status),
      updatedAt: Value(_stamp),
      dirty: const Value(true),
    ));
    if (rows == 0) throw RowNotFoundError('accessories', id);
  }

  Future<void> markLost(String id) => _setStatus(id, AccessoryStatus.lost);

  Future<void> retire(String id) => _setStatus(id, AccessoryStatus.retired);
}
