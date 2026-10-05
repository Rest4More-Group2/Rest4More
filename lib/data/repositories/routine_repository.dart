import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/converters.dart';
import '../database/enums.dart';
import '../database/local_types.dart';
import 'repository_support.dart';

class RoutineRepository {
  RoutineRepository(this._db, {this._now = DateTime.now});

  final AppDatabase _db;
  final Clock _now;

  DateTime get _stamp => _now().toUtc();

  Stream<List<Routine>> watchAll() => (_db.select(_db.routines)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.name), (t) => OrderingTerm.asc(t.id)]))
      .watch();

  Future<Routine> create({
    required String mode,
    required String name,
    RoutineEndRule endRule = RoutineEndRule.manual,
    int? defaultMinutes,
    String? blockProfileId,
  }) {
    return _db.into(_db.routines).insertReturning(RoutinesCompanion.insert(
          mode: mode,
          name: name,
          updatedAt: _stamp,
          endRule: Value(endRule),
          defaultMinutes: Value(defaultMinutes),
          blockProfileId: Value(blockProfileId),
        ));
  }

  Future<void> _write(String id, RoutinesCompanion changes) async {
    final rows = await (_db.update(_db.routines)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .write(changes.copyWith(
      updatedAt: Value(_stamp),
      dirty: const Value(true),
    ));
    if (rows == 0) throw RowNotFoundError('routines', id);
  }

  /// Werkt alleen de meegegeven velden bij.
  Future<void> update(
    String id, {
    String? mode,
    String? name,
    RoutineEndRule? endRule,
    int? defaultMinutes,
    String? blockProfileId,
    bool? enabled,
  }) =>
      _write(
        id,
        RoutinesCompanion(
          mode: Value.absentIfNull(mode),
          name: Value.absentIfNull(name),
          endRule: Value.absentIfNull(endRule),
          defaultMinutes: Value.absentIfNull(defaultMinutes),
          blockProfileId: Value.absentIfNull(blockProfileId),
          enabled: Value.absentIfNull(enabled),
        ),
      );

  Future<void> softDelete(String id) =>
      _write(id, RoutinesCompanion(deletedAt: Value(_stamp)));

  Future<void> setSteps(String routineId, List<RoutineStepData> steps) =>
      _write(routineId, RoutinesCompanion(steps: Value(steps)));

  Future<void> setSchedule(
    String routineId,
    WeekdayMask days,
    int? startMinutes,
    bool autoStart,
  ) async {
    checkedMinutes(startMinutes, 'startMinutes');
    await _write(
      routineId,
      RoutinesCompanion(
        daysMask: Value(days.value),
        startMinutes: Value(startMinutes),
        autoStart: Value(autoStart),
      ),
    );
  }
}
