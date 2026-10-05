import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Bewaartermijn voor zacht verwijderde rijen: na [years] jaar worden ze echt
/// gewist. Dezelfde regel draait op de server (`purge_old_tombstones`).
///
/// Een verwijdering die nog niet naar de server is gestuurd (`dirty`) blijft
/// staan, anders zou de server de rij voor altijd houden. Zonder toestemming
/// voor synchronisatie is er geen servercopy, dan telt dat niet mee.
class RetentionService {
  RetentionService(
    this._db, {
    this.years = 2,
    this._now = DateTime.now,
  });

  final AppDatabase _db;
  final int years;
  final DateTime Function() _now;

  /// Kinderen eerst, zodat verwijzingen niet in de weg zitten.
  late final List<(String, TableInfo)> _tables = [
    ('programme_days', _db.programmeDays),
    ('programme_enrollments', _db.programmeEnrollments),
    ('focus_sessions', _db.focusSessions),
    ('routines', _db.routines),
    ('accessories', _db.accessories),
    ('block_profiles', _db.blockProfiles),
    ('profiles', _db.profiles),
  ];

  /// Wist verlopen verwijderde rijen. Geeft per tabel terug hoeveel rijen
  /// direct zijn gewist.
  Future<Map<String, int>> purgeOldTombstones() {
    return _db.transaction(() async {
      final n = _now().toUtc();
      final cutoff =
          DateTime.utc(n.year - years, n.month, n.day, n.hour, n.minute, n.second)
              .toIso8601String();
      final consentRows = await _db
          .customSelect(
            'SELECT 1 AS ok FROM profiles WHERE deleted_at IS NULL '
            'AND cloud_sync_consent_at IS NOT NULL LIMIT 1',
          )
          .get();
      final hasConsent = consentRows.isNotEmpty;

      final removed = <String, int>{};
      for (final (name, table) in _tables) {
        // Een profiel blijft staan zolang een deelname ernaar verwijst.
        final guard = name == 'profiles'
            ? ' AND NOT EXISTS (SELECT 1 FROM programme_enrollments e '
                'WHERE e.profile_id = profiles.id)'
            : '';
        removed[name] = await _db.customUpdate(
          'DELETE FROM $name WHERE deleted_at IS NOT NULL AND deleted_at < ? '
          'AND (dirty = 0 OR ? = 0)$guard',
          variables: [
            Variable<String>(cutoff),
            Variable<int>(hasConsent ? 1 : 0),
          ],
          updates: {table},
          updateKind: UpdateKind.delete,
        );
      }
      return removed;
    });
  }
}
