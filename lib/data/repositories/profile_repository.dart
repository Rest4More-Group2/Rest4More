import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/enums.dart';
import 'consent_repository.dart';
import 'repository_support.dart';

/// Antwoorden die worden bijgewerkt. Alleen velden die niet null zijn worden
/// geschreven, bestaande waarden blijven dus staan.
class ProfileDraft {
  const ProfileDraft({
    this.displayName,
    this.ageBand,
    this.primaryGoal,
    this.obstacle,
    this.rhythm,
    this.putawayMinutes,
    this.stepSize,
    this.preferredActivity,
    this.anchorText,
    this.activityMaterial,
    this.ownsRestnest,
    this.ownsCard,
    this.bedtimeMinutes,
    this.phoneAwayMinutes,
    this.timezone,
  });

  final String? displayName;
  final AgeBand? ageBand;
  final PrimaryGoal? primaryGoal;
  final Obstacle? obstacle;
  final Rhythm? rhythm;
  final int? putawayMinutes;
  final StepSize? stepSize;
  final PreferredActivity? preferredActivity;
  final String? anchorText;
  final String? activityMaterial;
  final bool? ownsRestnest;
  final bool? ownsCard;
  final int? bedtimeMinutes;
  final int? phoneAwayMinutes;
  final String? timezone;

  ProfilesCompanion _toCompanion() {
    checkedMinutes(bedtimeMinutes, 'bedtimeMinutes');
    checkedMinutes(phoneAwayMinutes, 'phoneAwayMinutes');
    return ProfilesCompanion(
      displayName: Value.absentIfNull(displayName),
      ageBand: Value.absentIfNull(ageBand),
      primaryGoal: Value.absentIfNull(primaryGoal),
      obstacle: Value.absentIfNull(obstacle),
      rhythm: Value.absentIfNull(rhythm),
      putawayMinutes: Value.absentIfNull(putawayMinutes),
      stepSize: Value.absentIfNull(stepSize),
      preferredActivity: Value.absentIfNull(preferredActivity),
      anchorText: Value.absentIfNull(anchorText),
      activityMaterial: Value.absentIfNull(activityMaterial),
      ownsRestnest: Value.absentIfNull(ownsRestnest),
      ownsCard: Value.absentIfNull(ownsCard),
      bedtimeMinutes: Value.absentIfNull(bedtimeMinutes),
      phoneAwayMinutes: Value.absentIfNull(phoneAwayMinutes),
      timezone: Value.absentIfNull(timezone),
    );
  }
}

/// Cloudsynchronisatie mag niet voor deze gebruiker (leeftijd onbekend of
/// jonger dan 16).
class CloudSyncNotAllowedError implements Exception {
  const CloudSyncNotAllowedError();

  @override
  String toString() => 'CloudSyncNotAllowedError';
}

/// Het profiel van de gebruiker. Er is precies een rij, die bij eerste gebruik
/// wordt aangemaakt.
class ProfileRepository {
  ProfileRepository(this._db, {this._now = DateTime.now});

  /// Cloudsynchronisatie vraagt een bekende leeftijd van 16 of ouder. De
  /// Nederlandse leeftijd voor digitale toestemming is 16 (AVG art. 8).
  static bool isCloudSyncAllowedFor(AgeBand? band) =>
      band == AgeBand.age16To17 ||
      band == AgeBand.age18To24 ||
      band == AgeBand.age25To39 ||
      band == AgeBand.age40To54 ||
      band == AgeBand.age55Plus;

  final AppDatabase _db;
  final Clock _now;

  DateTime get _stamp => _now().toUtc();

  SimpleSelectStatement<$ProfilesTable, Profile> get _query =>
      _db.select(_db.profiles)
        ..where((t) => t.deletedAt.isNull())
        ..limit(1);

  /// Volgt het profiel. Maakt de rij aan bij het eerste abonnement.
  Stream<Profile> watch() async* {
    await get();
    yield* _query.watchSingle();
  }

  /// Geeft het profiel en maakt het aan als het nog niet bestaat.
  Future<Profile> get() {
    return _db.transaction(() async {
      final existing = await _query.getSingleOrNull();
      if (existing != null) return existing;
      await _db.into(_db.profiles).insert(
            ProfilesCompanion.insert(updatedAt: _stamp),
          );
      return _query.getSingle();
    });
  }

  Future<void> _write(ProfilesCompanion changes) async {
    final profile = await get();
    await (_db.update(_db.profiles)..where((t) => t.id.equals(profile.id)))
        .write(changes.copyWith(
      updatedAt: Value(_stamp),
      dirty: const Value(true),
    ));
  }

  Future<void> upsert(ProfileDraft draft) => _writeAnswers(draft._toCompanion(), draft);

  /// Schrijft antwoorden. Wordt de leeftijd onder de grens gezet terwijl er
  /// toestemming is, dan wordt die toestemming meteen ingetrokken. De data in
  /// de cloud moet de aanroeper apart laten wissen (`CloudDataService`).
  Future<void> _writeAnswers(ProfilesCompanion changes, ProfileDraft? draft) {
    return _db.transaction(() async {
      final band = draft?.ageBand;
      final blocked = band != null && !isCloudSyncAllowedFor(band);
      final profile = await get();
      final withdraw = blocked && profile.cloudSyncConsentAt != null;
      await _write(withdraw
          ? changes.copyWith(cloudSyncConsentAt: const Value(null))
          : changes);
      if (withdraw) {
        await ConsentRepository(_db, now: _now)
            .record(ConsentPurpose.cloudSync, ConsentStatus.withdrawn);
      }
    });
  }

  /// Bewaart de voortgang van de intake, zodat die na een onderbreking kan
  /// hervatten.
  Future<void> saveIntakeStep(int step, {ProfileDraft? answers}) async {
    if (step < 0) throw InvalidValueError('step mag niet negatief zijn: $step');
    final base = answers?._toCompanion() ?? const ProfilesCompanion();
    await _writeAnswers(base.copyWith(intakeStep: Value(step)), answers);
  }

  Future<void> completeIntake() =>
      _write(ProfilesCompanion(intakeCompletedAt: Value(_stamp)));

  Future<void> setNotification({required bool enabled, int? minutes}) async {
    checkedMinutes(minutes, 'minutes');
    await _write(ProfilesCompanion(
      notifyProgramme: Value(enabled),
      notifyTimeMinutes: Value.absentIfNull(minutes),
    ));
  }

  /// Zet het moment van toestemming voor synchronisatie en legt het vast als
  /// bewijs, met de versie van de privacytekst. Null trekt de toestemming in.
  /// Gooit [CloudSyncNotAllowedError] als de leeftijd onbekend is of onder de
  /// 16 ligt.
  Future<void> recordCloudSyncConsent(
    DateTime? at, {
    String policyVersion = currentCloudSyncPolicyVersion,
  }) {
    return _db.transaction(() async {
      final profile = await get();
      if (at != null && !isCloudSyncAllowedFor(profile.ageBand)) {
        throw const CloudSyncNotAllowedError();
      }
      await _write(ProfilesCompanion(cloudSyncConsentAt: Value(at?.toUtc())));
      await ConsentRepository(_db, now: _now).record(
        ConsentPurpose.cloudSync,
        at == null ? ConsentStatus.withdrawn : ConsentStatus.granted,
        policyVersion: policyVersion,
      );
    });
  }
}
