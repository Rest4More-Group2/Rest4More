import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/converters.dart';
import '../database/enums.dart';
import '../repositories/entitlement_repository.dart';
import 'sync_remote.dart';
import 'sync_tables.dart';

/// Uitkomst van een pull. Fouten worden teruggegeven, niet gegooid.
class PullResult {
  const PullResult({
    this.applied = 0,
    this.skipped = 0,
    this.conflicts = const [],
    this.skippedNoSession = false,
    this.failedTable,
    this.error,
  });

  /// Rijen die lokaal zijn toegevoegd of bijgewerkt.
  final int applied;

  /// Rijen die niet pasten, bijvoorbeeld een tweede open sessie.
  final int skipped;

  /// Beschrijvingen van conflicten waar de lokale gegevens zijn blijven staan.
  final List<String> conflicts;

  /// Er is geen sessie, dus er is niets opgehaald.
  final bool skippedNoSession;
  final String? failedTable;
  final Object? error;

  bool get ok => error == null && !skippedNoSession;
}

/// Haalt wijzigingen van de server op en past ze lokaal toe (alleen pull).
///
/// - De server is leidend als de rij daar nieuwer is (`updated_at`), de lokale
///   rij blijft als die nieuwer of gelijk is. Dat is dezelfde regel als op de
///   server bij pushen.
/// - Opgehaalde rijen zijn nooit `dirty`, dus een pull veroorzaakt geen push.
/// - Onbekende enumwaarden gaan letterlijk mee, er wordt niets herschreven.
/// - Rijen die lokaal niet passen (bijvoorbeeld een tweede open sessie)
///   worden overgeslagen en geteld, de pull gaat door.
/// - Maakt nooit een account aan: zonder bestaande sessie gebeurt er niets.
class PullEngine {
  PullEngine(
    this._db,
    this._remote, {
    this.pageSize = 200,
    this.overlap = const Duration(minutes: 2),
  });

  final AppDatabase _db;
  final SyncRemote _remote;
  final int pageSize;

  /// De server stempelt `synced_at` bij het begin van een transactie. Een
  /// transactie die later klaar is kan dus een oudere tijd hebben dan we al
  /// gezien hebben. Daarom beginnen we iets vóór de laatste positie, en
  /// pasgemaakte rijen worden toch niet dubbel toegepast.
  final Duration overlap;

  static const _nilUuid = '00000000-0000-0000-0000-000000000000';
  static const _skipColumns = {'user_id', 'synced_at'};

  late final List<SyncTableSpec> _tables = syncTableSpecs(_db);

  Future<PullResult> pull() async {
    if (_remote.currentUserId == null) {
      return const PullResult(skippedNoSession: true);
    }

    var applied = 0;
    var skipped = 0;
    final conflicts = <String>[];
    String? current;
    try {
      for (final table in _tables) {
        current = table.name;
        final outcome = await _pullTable(table);
        applied += outcome.applied;
        skipped += outcome.skipped;
        conflicts.addAll(outcome.conflicts);
      }
      current = 'entitlements';
      await _pullEntitlements();
      return PullResult(applied: applied, skipped: skipped, conflicts: conflicts);
    } on Exception catch (error) {
      return PullResult(
        applied: applied,
        skipped: skipped,
        conflicts: conflicts,
        failedTable: current,
        error: error,
      );
    }
  }

  Future<String?> _cursor(String table) async {
    final row = await (_db.select(_db.syncCursors)
          ..where((t) => t.targetTable.equals(table)))
        .getSingleOrNull();
    return row?.cursor;
  }

  Future<void> _saveCursor(String table, String cursor) =>
      _db.into(_db.syncCursors).insertOnConflictUpdate(
            SyncCursorsCompanion.insert(targetTable: table, cursor: cursor),
          );

  Future<({int applied, int skipped, List<String> conflicts})> _pullTable(
    SyncTableSpec table,
  ) async {
    var applied = 0;
    var skipped = 0;
    final conflicts = <String>[];

    final saved = await _cursor(table.name);
    SyncPosition? position;
    if (saved != null) {
      // Een stukje terug beginnen, zie [overlap].
      final start = DateTime.parse(saved).subtract(overlap).toUtc();
      position = SyncPosition(start.toIso8601String(), _nilUuid);
    }

    String? latest = saved;
    while (true) {
      final rows = await _remote.fetchChanges(
        table.name,
        after: position,
        limit: pageSize,
      );
      if (rows.isEmpty) break;

      await _db.transaction(() async {
        for (final row in rows) {
          final outcome = await _applyRow(table, row);
          applied += outcome.applied ? 1 : 0;
          skipped += outcome.skipped ? 1 : 0;
          if (outcome.conflict != null) conflicts.add(outcome.conflict!);
        }
      });

      final last = rows.last;
      position = SyncPosition(last['synced_at'] as String, last['id'] as String);
      latest = _later(latest, position.syncedAt);
      // Per pagina bewaren: een onderbroken pull gaat daar verder.
      await _saveCursor(table.name, latest);
      if (rows.length < pageSize) break;
    }
    return (applied: applied, skipped: skipped, conflicts: conflicts);
  }

  String _later(String? a, String b) {
    if (a == null) return b;
    return DateTime.parse(b).isAfter(DateTime.parse(a)) ? b : a;
  }

  Future<({bool applied, bool skipped, String? conflict})> _applyRow(
    SyncTableSpec table,
    Map<String, Object?> row,
  ) async {
    final id = row['id'] as String;
    final serverUpdated = DateTime.parse(row['updated_at'] as String);

    if (table.name == 'profiles') {
      final conflict = await _makeRoomForProfile(id);
      if (conflict != null) {
        return (applied: false, skipped: false, conflict: conflict);
      }
    }

    final local = await _db
        .customSelect(
          'SELECT updated_at FROM ${table.name} WHERE id = ?',
          variables: [Variable<String>(id)],
        )
        .getSingleOrNull();
    if (local != null) {
      final localUpdated = DateTime.parse(local.read<String>('updated_at'));
      // Alleen een nieuwere serverversie wint.
      if (!serverUpdated.isAfter(localUpdated)) {
        return (applied: false, skipped: false, conflict: null);
      }
    }

    final values = _toLocal(table, row);
    try {
      if (local == null) {
        final columns = values.keys.toList();
        await _db.customUpdate(
          'INSERT INTO ${table.name} (${columns.join(', ')}) '
          'VALUES (${List.filled(columns.length, '?').join(', ')})',
          variables: [for (final c in columns) _variable(values[c])],
          updates: {table.table},
          updateKind: UpdateKind.insert,
        );
      } else {
        final columns = values.keys.where((c) => c != 'id').toList();
        await _db.customUpdate(
          'UPDATE ${table.name} SET ${columns.map((c) => '$c = ?').join(', ')} '
          'WHERE id = ?',
          variables: [
            for (final c in columns) _variable(values[c]),
            Variable<String>(id),
          ],
          updates: {table.table},
          updateKind: UpdateKind.update,
        );
      }
      return (applied: true, skipped: false, conflict: null);
    } on Exception {
      // Past lokaal niet (unieke index of verwijzing), de rest gaat door.
      return (applied: false, skipped: true, conflict: null);
    }
  }

  /// Er is lokaal maar plaats voor een profiel. Een leeg, net aangemaakt
  /// profiel met een andere id wordt vervangen door dat van de server. Een
  /// profiel met gegevens blijft staan, en dat wordt als conflict gemeld.
  Future<String?> _makeRoomForProfile(String serverId) async {
    final others = await _db
        .customSelect(
          'SELECT id, intake_step, intake_completed_at, display_name, age_band, '
          '(SELECT COUNT(*) FROM programme_enrollments e '
          'WHERE e.profile_id = profiles.id) AS enrollments '
          'FROM profiles WHERE id != ? AND deleted_at IS NULL',
          variables: [Variable<String>(serverId)],
        )
        .get();
    for (final other in others) {
      final pristine = other.read<int>('intake_step') == 0 &&
          other.read<String?>('intake_completed_at') == null &&
          other.read<String?>('display_name') == null &&
          other.read<String?>('age_band') == null &&
          other.read<int>('enrollments') == 0;
      if (!pristine) {
        return 'Lokaal profiel ${other.read<String>('id')} heeft gegevens en '
            'wijkt af van het serverprofiel $serverId. Niets overschreven.';
      }
      await _db.customUpdate(
        'DELETE FROM profiles WHERE id = ?',
        variables: [Variable<String>(other.read<String>('id'))],
        updates: {_db.profiles},
        updateKind: UpdateKind.delete,
      );
    }
    return null;
  }

  Variable _variable(Object? value) => switch (value) {
        null => const Variable<Object>(null),
        int v => Variable<int>(v),
        double v => Variable<double>(v),
        String v => Variable<String>(v),
        _ => Variable<String>(value.toString()),
      };

  /// Zet een serverrij om naar lokale kolomwaarden.
  Map<String, Object?> _toLocal(SyncTableSpec table, Map<String, Object?> row) {
    final out = <String, Object?>{};
    row.forEach((column, value) {
      if (_skipColumns.contains(column)) return;
      if (value == null) {
        out[column] = null;
      } else if (table.bools.contains(column)) {
        out[column] = value == true ? 1 : 0;
      } else if (table.json.containsKey(column)) {
        out[column] = jsonEncode(value);
      } else if (column.endsWith('_at') && value is String) {
        out[column] =
            DateTime.tryParse(value)?.toUtc().toIso8601String() ?? value;
      } else {
        out[column] = value;
      }
    });
    out['dirty'] = 0;
    return out;
  }

  /// Rechten zijn van de server: altijd de volledige lijst, zonder cursor.
  Future<void> _pullEntitlements() async {
    final all = <Entitlement>[];
    SyncPosition? position;
    while (true) {
      final rows = await _remote.fetchChanges(
        'entitlements',
        after: position,
        limit: pageSize,
      );
      for (final row in rows) {
        if (row['deleted_at'] != null) continue;
        all.add(_toEntitlement(row));
      }
      if (rows.length < pageSize) break;
      final last = rows.last;
      position = SyncPosition(last['synced_at'] as String, last['id'] as String);
    }
    await EntitlementRepository(_db).replaceFromServer(all);
  }

  Entitlement _toEntitlement(Map<String, Object?> row) => Entitlement(
        id: row['id'] as String,
        updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
        deletedAt: null,
        dirty: false,
        feature: row['feature'] as String,
        source: const DbEnumConverter(
                EntitlementSource.values, EntitlementSource.unknown)
            .fromSql(row['source'] as String),
        status: const DbEnumConverter(
                EntitlementStatus.values, EntitlementStatus.unknown)
            .fromSql(row['status'] as String),
        startsAt: DateTime.parse(row['starts_at'] as String).toUtc(),
        endsAt: row['ends_at'] == null
            ? null
            : DateTime.parse(row['ends_at'] as String).toUtc(),
      );
}
