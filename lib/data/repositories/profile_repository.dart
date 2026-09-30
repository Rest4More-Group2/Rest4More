import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/enums.dart';
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

/// Het profiel van de gebruiker. Er is precies een rij, die bij eerste gebruik
/// wordt aangemaakt.
class ProfileRepository {
  ProfileRepository(this._db, {this._now = DateTime.now});

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

  Future<void> upsert(ProfileDraft draft) => _write(draft._toCompanion());

  /// Bewaart de voortgang van de intake, zodat die na een onderbreking kan
  /// hervatten.
  Future<void> saveIntakeStep(int step, {ProfileDraft? answers}) {
    if (step < 0) throw InvalidValueError('step mag niet negatief zijn: $step');
    final base = answers?._toCompanion() ?? const ProfilesCompanion();
    return _write(base.copyWith(intakeStep: Value(step)));
  }

  Future<void> completeIntake() =>
      _write(ProfilesCompanion(intakeCompletedAt: Value(_stamp)));

  Future<void> setNotification({required bool enabled, int? minutes}) {
    checkedMinutes(minutes, 'minutes');
    return _write(ProfilesCompanion(
      notifyProgramme: Value(enabled),
      notifyTimeMinutes: Value.absentIfNull(minutes),
    ));
  }

  /// Zet het moment van toestemming voor synchronisatie. Null trekt de
  /// toestemming in.
  Future<void> recordCloudSyncConsent(DateTime? at) => _write(
        ProfilesCompanion(cloudSyncConsentAt: Value(at?.toUtc())),
      );
}
