import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/enums.dart';
import 'repository_support.dart';

/// Bewaart de plannen van Avond en Ochtend. Per soort telt de nieuwste
/// levende rij.
class MomentPlanRepository {
  MomentPlanRepository(this._db, {this._now = DateTime.now});

  final AppDatabase _db;
  final Clock _now;

  SimpleSelectStatement<$MomentPlansTable, MomentPlan> _live(
    MomentPlanKind kind,
  ) =>
      _db.select(_db.momentPlans)
        ..where((t) => t.kind.equalsValue(kind) & t.deletedAt.isNull())
        ..orderBy([
          (t) => OrderingTerm.desc(t.updatedAt),
          (t) => OrderingTerm.asc(t.id),
        ]);

  /// Het plan als json-tekst, of null als er nog geen is.
  Future<String?> get(MomentPlanKind kind) async {
    final rows = await (_live(kind)..limit(1)).get();
    return rows.isEmpty ? null : rows.single.plan;
  }

  Stream<String?> watch(MomentPlanKind kind) => (_live(kind)..limit(1))
      .watch()
      .map((rows) => rows.isEmpty ? null : rows.single.plan);

  /// Bewaart het plan. Er is er één per soort: bestaat er al een, dan wordt
  /// die bijgewerkt. Dubbelen (bijvoorbeeld van een tweede toestel) worden
  /// zacht verwijderd, zodat ze ook op de server opruimen.
  Future<void> save(MomentPlanKind kind, String planJson) {
    return _db.transaction(() async {
      final stamp = _now().toUtc();
      final rows = await _live(kind).get();
      if (rows.isEmpty) {
        await _db.into(_db.momentPlans).insert(MomentPlansCompanion.insert(
              kind: kind,
              plan: planJson,
              updatedAt: stamp,
            ));
        return;
      }
      await (_db.update(_db.momentPlans)
            ..where((t) => t.id.equals(rows.first.id)))
          .write(MomentPlansCompanion(
        plan: Value(planJson),
        updatedAt: Value(stamp),
        dirty: const Value(true),
      ));
      for (final extra in rows.skip(1)) {
        await (_db.update(_db.momentPlans)..where((t) => t.id.equals(extra.id)))
            .write(MomentPlansCompanion(
          deletedAt: Value(stamp),
          updatedAt: Value(stamp),
          dirty: const Value(true),
        ));
      }
    });
  }
}
