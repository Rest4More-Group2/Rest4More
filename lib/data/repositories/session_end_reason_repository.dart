import '../database/app_database.dart';
import '../database/enums.dart';
import 'repository_support.dart';

/// Redenen voor eerder stoppen. Alleen lokaal: deze tabel hoort niet bij de
/// sync en verlaat het toestel niet.
class SessionEndReasonRepository {
  SessionEndReasonRepository(this._db, {this._now = DateTime.now});

  final AppDatabase _db;
  final Clock _now;

  /// Bewaart de reden. Null wist een eerder gekozen reden.
  Future<void> set(String sessionId, EndReason? reason) async {
    if (reason == null || reason == EndReason.unknown) {
      await (_db.delete(_db.sessionEndReasons)
            ..where((t) => t.sessionId.equals(sessionId)))
          .go();
      return;
    }
    await _db.into(_db.sessionEndReasons).insertOnConflictUpdate(
          SessionEndReasonsCompanion.insert(
            sessionId: sessionId,
            reason: reason,
            recordedAt: _now().toUtc(),
          ),
        );
  }

  /// Alle redenen, per sessie-id.
  Stream<Map<String, EndReason>> watchAll() =>
      _db.select(_db.sessionEndReasons).watch().map(
            (rows) => {for (final r in rows) r.sessionId: r.reason},
          );
}
