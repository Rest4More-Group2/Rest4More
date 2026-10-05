import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/enums.dart';
import 'repository_support.dart';

/// Versie van de privacytekst voor cloudsynchronisatie. Verhoog dit als de
/// tekst inhoudelijk verandert: gebruikers moeten dan opnieuw instemmen.
const currentCloudSyncPolicyVersion = '2026-10-v1';

/// Legt toestemming vast als reeks rijen die alleen wordt aangevuld.
class ConsentRepository {
  ConsentRepository(this._db, {this._now = DateTime.now});

  final AppDatabase _db;
  final Clock _now;

  Future<ConsentRecord> record(
    ConsentPurpose purpose,
    ConsentStatus status, {
    String policyVersion = currentCloudSyncPolicyVersion,
  }) {
    final now = _now().toUtc();
    return _db.into(_db.consentRecords).insertReturning(
          ConsentRecordsCompanion.insert(
            purpose: purpose,
            policyVersion: policyVersion,
            status: status,
            recordedAt: now,
            updatedAt: now,
          ),
        );
  }

  /// Laatste vastgelegde stap voor dit doel, of null.
  Future<ConsentRecord?> latest(ConsentPurpose purpose) =>
      (_db.select(_db.consentRecords)
            ..where((t) => t.purpose.equals(purpose.id))
            ..orderBy([
              (t) => OrderingTerm.desc(t.recordedAt),
              (t) => OrderingTerm.desc(t.updatedAt),
            ])
            ..limit(1))
          .getSingleOrNull();

  Stream<List<ConsentRecord>> watchAll() => (_db.select(_db.consentRecords)
        ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
      .watch();

  /// True als er toestemming is gegeven voor een andere (oudere) versie van de
  /// tekst dan de huidige, of als die is ingetrokken.
  Future<bool> needsReconsent(
    ConsentPurpose purpose, {
    String currentVersion = currentCloudSyncPolicyVersion,
  }) async {
    final last = await latest(purpose);
    return last == null ||
        last.status != ConsentStatus.granted ||
        last.policyVersion != currentVersion;
  }
}
