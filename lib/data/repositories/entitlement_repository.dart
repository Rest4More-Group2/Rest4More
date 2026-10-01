import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/enums.dart';
import 'repository_support.dart';

/// Rechten komen van de server. De app leest ze en stuurt niets terug.
class EntitlementRepository {
  EntitlementRepository(this._db, {this._now = DateTime.now});

  final AppDatabase _db;
  final Clock _now;

  /// Rechten met status `active` die niet zijn verlopen. De tijd wordt
  /// bepaald bij het starten van de query.
  Stream<List<Entitlement>> watchActive() {
    final now = _now().toUtc();
    return (_db.select(_db.entitlements)
          ..where((t) =>
              t.status.equals(EntitlementStatus.active.id) &
              t.deletedAt.isNull() &
              (t.endsAt.isNull() | t.endsAt.isBiggerThanValue(now))))
        .watch();
  }

  /// Neemt de lijst van de server over voor de latere pull, in een
  /// transactie. Rijen die de server niet meer noemt worden echt verwijderd,
  /// de rest wordt toegevoegd of bijgewerkt. De server is de eigenaar, dus
  /// niets hiervan is `dirty` en er is geen zachte verwijdering.
  Future<void> replaceFromServer(List<Entitlement> incoming) {
    return _db.transaction(() async {
      final ids = incoming.map((e) => e.id).toSet();
      await (_db.delete(_db.entitlements)..where((t) => t.id.isNotIn(ids)))
          .go();
      for (final entitlement in incoming) {
        await _db.into(_db.entitlements).insertOnConflictUpdate(
              entitlement.copyWith(dirty: false).toCompanion(true),
            );
      }
    });
  }
}
