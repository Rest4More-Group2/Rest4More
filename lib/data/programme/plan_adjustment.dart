import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/enums.dart';
import '../repositories/profile_repository.dart';
import '../repositories/programme_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/plan_labels.dart';
import 'content_catalog.dart';
import 'plan_explanation.dart';
import 'plan_input.dart';
import 'plan_scheduler.dart';
import 'plan_selector.dart';
import 'plan_service.dart';

/// Eén regel in het overzicht voor het bevestigen: wat er was en wat het wordt.
class PlanChange {
  const PlanChange(this.label, this.before, this.after);

  final String label;
  final String before;
  final String after;
}

/// Wat de gebruiker aan het plan wil veranderen. Alleen velden die niet null
/// zijn veranderen; de andere antwoorden blijven zoals ze waren.
class PlanAdjustment {
  const PlanAdjustment({this.goal, this.obstacle, this.activity, this.stepSize});

  /// Alleen wat echt anders is dan in [profile].
  factory PlanAdjustment.between(
    Profile profile, {
    required PrimaryGoal? goal,
    required Obstacle? obstacle,
    required PreferredActivity? activity,
    required bool smaller,
  }) {
    final wasSmaller = profile.stepSize == StepSize.short;
    return PlanAdjustment(
      goal: goal != profile.primaryGoal ? goal : null,
      obstacle: obstacle != profile.obstacle ? obstacle : null,
      activity: activity != profile.preferredActivity ? activity : null,
      stepSize: smaller == wasSmaller
          ? null
          : (smaller ? StepSize.short : StepSize.standard),
    );
  }

  final PrimaryGoal? goal;
  final Obstacle? obstacle;
  final PreferredActivity? activity;
  final StepSize? stepSize;

  bool get isEmpty =>
      goal == null && obstacle == null && activity == null && stepSize == null;

  /// Alleen de grootte van de stappen verandert, de inhoud niet.
  bool get onlyStepSize =>
      stepSize != null && goal == null && obstacle == null && activity == null;

  ProfileDraft toDraft() => ProfileDraft(
        primaryGoal: goal,
        obstacle: obstacle,
        preferredActivity: activity,
        stepSize: stepSize,
      );

  /// Het profiel zoals het na bevestigen is, om het plan vooraf te tonen.
  Profile applyTo(Profile profile) => profile.copyWith(
        primaryGoal: goal == null ? const Value.absent() : Value(goal),
        obstacle: obstacle == null ? const Value.absent() : Value(obstacle),
        preferredActivity:
            activity == null ? const Value.absent() : Value(activity),
        stepSize: stepSize == null ? const Value.absent() : Value(stepSize),
      );

  List<PlanChange> changesFrom(Profile profile, {AppLocalizations? l10n}) {
    final t = l10n ?? englishL10n();
    String goalText(PrimaryGoal? g) =>
        g == null || g == PrimaryGoal.unknown
            ? t.notChosen
            : goalLabel(t, g.id);
    String obstacleText(Obstacle? o) =>
        o == null || o == Obstacle.unknown
            ? t.notChosen
            : obstacleLabel(t, o.id);
    String activityText(PreferredActivity? a) =>
        PlanExplanation.activityLabel(t, PlanPhrases.forActivity(a, t).activity) ??
        t.notChosen;
    String sizeText(StepSize? s) =>
        s == StepSize.short ? t.smallerSteps : t.standardSteps;
    return [
      if (goal != null)
        PlanChange(t.changeGoal, goalText(profile.primaryGoal), goalText(goal)),
      if (obstacle != null)
        PlanChange(t.reasonObstacle, obstacleText(profile.obstacle),
            obstacleText(obstacle)),
      if (activity != null)
        PlanChange(t.calmActivity, activityText(profile.preferredActivity),
            activityText(activity)),
      if (stepSize != null)
        PlanChange(t.reasonStepSize, sizeText(profile.stepSize), sizeText(stepSize)),
    ];
  }
}

/// Voert een bevestigde aanpassing door. Schrijft alleen via de repositories.
class PlanAdjustmentService {
  PlanAdjustmentService(this._db, this._loadCatalog,
      {this._now = DateTime.now, this._l10n});

  final AppDatabase _db;
  final Future<ContentCatalog> Function() _loadCatalog;
  final DateTime Function() _now;
  final AppLocalizations Function()? _l10n;

  /// Bewaart de gewijzigde antwoorden. Tijdens de onboarding is dat genoeg:
  /// het plan wordt aan het eind gemaakt. Loopt er al een programma, dan wordt
  /// het nieuwe plan meteen het actieve. Alleen een andere stapgrootte past de
  /// dagen die nog komen aan, zodat er geen voortgang verloren gaat.
  Future<void> confirm(PlanAdjustment change) async {
    if (change.isEmpty) return;
    final catalog = await _loadCatalog();
    final profiles = ProfileRepository(_db, now: _now);
    final programme = ProgrammeRepository(_db, now: _now);

    await _db.transaction(() async {
      await profiles.upsert(change.toDraft());
      final live = await _liveEnrollment();
      if (live == null) return;

      if (change.onlyStepSize) {
        final size =
            change.stepSize == StepSize.short ? DaySize.smaller : DaySize.standard;
        final days = await (_db.select(_db.programmeDays)
              ..where((t) =>
                  t.enrollmentId.equals(live.id) & t.deletedAt.isNull()))
            .get();
        for (final day in days) {
          if (day.status == DayStatus.completed ||
              day.status == DayStatus.skipped) {
            continue;
          }
          await programme.setSize(day.id, size);
        }
        return;
      }

      final input = PlanInput.fromProfile(await profiles.get(), l10n: _l10n?.call());
      if (input == null) return;
      final days = selectPlan(input, catalog, l10n: _l10n?.call());
      final start =
          planStartDate(now: _now(), reminderMinutes: input.reminderMinutes);
      final dates = planDates(start);

      await programme.stop(live.id);
      final enrollment = await programme.enroll(
        contentVersion: catalog.version,
        selection: {...input.toJson(), 'rules_version': PlanService.rulesVersion},
        startedOn: start,
      );
      await programme.createDays(enrollment.id, [
        for (var i = 0; i < days.length; i++)
          DaySeed(
            dayNumber: days[i]['day'] as int,
            contentId: days[i]['content_id'] as String,
            scheduledFor: dates[i],
            size: input.smaller ? DaySize.smaller : DaySize.standard,
            snapshot: days[i],
          ),
      ]);
    });
  }

  Future<ProgrammeEnrollment?> _liveEnrollment() => (_db.select(
              _db.programmeEnrollments)
            ..where((t) =>
                t.status.isIn([
                  EnrollmentStatus.active.id,
                  EnrollmentStatus.paused.id,
                ]) &
                t.deletedAt.isNull())
            ..limit(1))
          .getSingleOrNull();
}
