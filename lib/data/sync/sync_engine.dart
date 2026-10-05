import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'sync_scheduler.dart';
import 'sync_remote.dart';

/// Uitkomst van een push. Fouten worden teruggegeven, niet gegooid: de rijen
/// blijven dan `dirty` en een volgende poging probeert het opnieuw.
class PushResult {
  const PushResult({
    this.pushed = 0,
    this.skippedNoConsent = false,
    this.failedTable,
    this.error,
  });

  final int pushed;

  /// Er is geen toestemming voor synchronisatie, dus er is niets verstuurd.
  final bool skippedNoConsent;
  final String? failedTable;
  final Object? error;

  bool get ok => error == null && !skippedNoConsent;
}

class _SyncTable {
  const _SyncTable(
    this.name,
    this.table, {
    this.bools = const {},
    this.json = const {},
  });

  final String name;
  final TableInfo table;

  /// Booleankolommen, lokaal opgeslagen als 0 en 1.
  final Set<String> bools;

  /// Jsonb-kolommen met de waarde als de opgeslagen tekst onleesbaar is.
  final Map<String, Object?> json;
}

/// Stuurt lokale wijzigingen naar de server (alleen push).
///
/// Leest de ruwe rijen, zodat onbekende enumwaarden letterlijk meegaan. Geen
/// `dirty` en geen `user_id` in de payload, de server vult die. Entitlements
/// en de lokale-only tabellen worden nooit verstuurd.
class SyncEngine {
  SyncEngine(
    this._db,
    this._remote, {
    this.batchSize = 100,
    this._state,
  });

  final AppDatabase _db;
  final SyncRemote _remote;
  final SyncStateStore? _state;
  final int batchSize;

  /// Ouders eerst, want kinderen verwijzen naar hun rij op de server.
  late final List<_SyncTable> _tables = [
    _SyncTable('profiles', _db.profiles,
        bools: {'owns_restnest', 'owns_card', 'notify_programme'}),
    _SyncTable('block_profiles', _db.blockProfiles, json: {'items': <Object?>[]}),
    _SyncTable('routines', _db.routines,
        bools: {'auto_start', 'enabled'}, json: {'steps': null}),
    _SyncTable('accessories', _db.accessories),
    _SyncTable('focus_sessions', _db.focusSessions,
        json: {'events': <Object?>[]}),
    _SyncTable('programme_enrollments', _db.programmeEnrollments,
        json: {'selection': <String, Object?>{}}),
    _SyncTable('programme_days', _db.programmeDays,
        json: {'snapshot': <String, Object?>{}}),
  ];

  Future<bool> _hasConsent() async {
    final rows = await _db
        .customSelect(
          'SELECT 1 AS ok FROM profiles WHERE deleted_at IS NULL '
          'AND cloud_sync_consent_at IS NOT NULL LIMIT 1',
          readsFrom: {_db.profiles},
        )
        .get();
    return rows.isNotEmpty;
  }

  /// Stuurt alle `dirty` rijen. Doet niets zonder toestemming.
  Future<PushResult> pushDirty() async {
    if (!await _hasConsent()) return const PushResult(skippedNoConsent: true);

    var pushed = 0;
    String? current;
    try {
      await _remote.ensureSignedIn();
      await _handleAccountChange();
      for (final table in _tables) {
        current = table.name;
        pushed += await _pushTable(table);
      }
      await _recordActivity();
      return PushResult(pushed: pushed);
    } on Exception catch (error) {
      return PushResult(pushed: pushed, failedTable: current, error: error);
    }
  }

  /// Als het serveraccount een ander is dan de vorige keer (bijvoorbeeld omdat
  /// het oude als verlaten is opgeruimd), bestaan de lokale gegevens daar niet.
  /// Markeer ze dan allemaal opnieuw als te versturen.
  Future<void> _handleAccountChange() async {
    final state = _state;
    final userId = _remote.currentUserId;
    if (state == null || userId == null) return;
    final previous = await state.lastUserId();
    if (previous != null && previous != userId) await markAllDirty();
    if (previous != userId) await state.saveUserId(userId);
  }

  /// Markeert alle gesynchroniseerde rijen als nog te versturen.
  Future<void> markAllDirty() async {
    await _db.transaction(() async {
      for (final table in _tables) {
        await _db.customUpdate(
          'UPDATE ${table.name} SET dirty = 1',
          updates: {table.table},
          updateKind: UpdateKind.update,
        );
      }
    });
  }

  /// Dagelijkse hartslag naar de server. Mislukt dit, dan is de push zelf
  /// nog steeds gelukt.
  Future<void> _recordActivity() async {
    try {
      await _remote.recordActivity();
    } on Exception {
      // Niet kritiek: de volgende dagelijkse push probeert het opnieuw.
    }
  }

  Future<int> _pushTable(_SyncTable table) async {
    var total = 0;
    while (true) {
      final rows = await _db
          .customSelect(
            'SELECT * FROM ${table.name} WHERE dirty = 1 '
            'ORDER BY updated_at, id LIMIT ?',
            variables: [Variable<int>(batchSize)],
            readsFrom: {table.table},
          )
          .get();
      if (rows.isEmpty) return total;

      await _remote.upsert(table.name, [
        for (final row in rows) _payload(table, row.data),
      ]);

      // Alleen schoonmaken als de rij sinds het lezen niet is gewijzigd,
      // anders gaat een bewerking tijdens het versturen verloren.
      var cleaned = 0;
      for (final row in rows) {
        cleaned += await _db.customUpdate(
          'UPDATE ${table.name} SET dirty = 0 WHERE id = ? AND updated_at = ?',
          variables: [
            Variable<String>(row.read<String>('id')),
            Variable<String>(row.read<String>('updated_at')),
          ],
          updates: {table.table},
          updateKind: UpdateKind.update,
        );
      }
      total += rows.length;
      if (cleaned == 0 || rows.length < batchSize) return total;
    }
  }

  Map<String, Object?> _payload(_SyncTable table, Map<String, Object?> data) {
    final out = <String, Object?>{};
    data.forEach((column, value) {
      if (column == 'dirty') return;
      if (value == null) {
        out[column] = null;
      } else if (table.bools.contains(column)) {
        out[column] = value == 1;
      } else if (table.json.containsKey(column)) {
        try {
          out[column] = jsonDecode(value as String);
        } catch (_) {
          out[column] = table.json[column];
        }
      } else if (column.endsWith('_at') && value is String) {
        out[column] =
            (DateTime.tryParse(value)?.toUtc().toIso8601String()) ?? value;
      } else {
        out[column] = value;
      }
    });
    return out;
  }
}
