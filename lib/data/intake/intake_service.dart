import '../database/app_database.dart';
import '../database/enums.dart';
import '../repositories/profile_repository.dart';

/// Hoe de keuzes in de onboardingschermen (een index per optie) worden
/// opgeslagen in het profiel. De volgorde hier moet gelijk zijn aan de volgorde
/// van de opties op het scherm.
class IntakeMapping {
  const IntakeMapping._();

  /// Goal: put the phone away earlier, build a routine, use less social media.
  static const goals = [
    PrimaryGoal.phone,
    PrimaryGoal.routine,
    PrimaryGoal.social,
  ];

  /// Obstacle: scrolling, availability, restless thoughts, planning, phone as
  /// alarm, no routine.
  static const obstacles = [
    Obstacle.scrolling,
    Obstacle.availability,
    Obstacle.thoughts,
    Obstacle.planning,
    Obstacle.alarm,
    Obstacle.noRoutine,
  ];

  /// Rhythm: 8 to 10 PM, 10 PM to 12 AM, after midnight. Bewaard als het begin
  /// van het uitwindvenster, in minuten sinds middernacht, in
  /// `bedtime_minutes`. Dat is een tijdelijke keuze tot de opdrachtgevers
  /// beslissen of dit een eigen kolom krijgt.
  static const windDownStartMinutes = [20 * 60, 22 * 60, 0];

  /// Activities: quiet moments, paper reading, evening breathing routines.
  static const activities = [
    PreferredActivity.quietSitting,
    PreferredActivity.reading,
    PreferredActivity.breathing,
  ];
}

/// Schermen van de onboarding, in volgorde.
enum OnboardingStep { welcome, goal, obstacle, rhythm, activities, plan, reminder, done }

/// Wat er van de intake is opgeslagen, als indexen die de schermen begrijpen.
class IntakeProgress {
  const IntakeProgress({
    required this.step,
    this.goal,
    this.obstacle,
    this.rhythm,
    this.activity,
    this.reminderEnabled = false,
    this.reminderMinutes,
    this.completed = false,
  });

  /// Het scherm waar de gebruiker verder moet.
  final OnboardingStep step;

  /// Index van de gekozen optie, of null als er nog niets is gekozen.
  final int? goal;

  /// Alleen de eerste gekozen belemmering wordt bewaard.
  final int? obstacle;
  final int? rhythm;

  /// Alleen de eerste gekozen activiteit wordt bewaard.
  final int? activity;
  final bool reminderEnabled;
  final int? reminderMinutes;
  final bool completed;
}

/// Bewaart de antwoorden uit de onboarding bij elk scherm, zodat een
/// onderbroken intake kan hervatten. Schrijft alleen via [ProfileRepository].
class IntakeService {
  IntakeService(this._profiles);

  final ProfileRepository _profiles;

  /// Stapnummers zoals opgeslagen in `intake_step`: het aantal afgeronde
  /// schermen met een keuze.
  static const _afterGoal = 1;
  static const _afterObstacle = 2;
  static const _afterRhythm = 3;
  static const _afterActivities = 4;
  static const _afterPlan = 5;

  Future<void> saveGoal(int index) async => _profiles.saveIntakeStep(
        _afterGoal,
        answers: ProfileDraft(primaryGoal: _pick(IntakeMapping.goals, index)),
      );

  /// [selected] in de volgorde waarin de gebruiker koos. De eerste telt als
  /// hoofdbelemmering, de rest wordt niet bewaard.
  Future<void> saveObstacles(Iterable<int> selected) async =>
      _profiles.saveIntakeStep(
        _afterObstacle,
        answers: selected.isEmpty
            ? null
            : ProfileDraft(
                obstacle: _pick(IntakeMapping.obstacles, selected.first)),
      );

  Future<void> saveRhythm(int index) async => _profiles.saveIntakeStep(
        _afterRhythm,
        answers: ProfileDraft(
          bedtimeMinutes: _pick(IntakeMapping.windDownStartMinutes, index),
        ),
      );

  /// [selected] in de volgorde waarin de gebruiker koos. De eerste wordt bewaard.
  Future<void> saveActivities(Iterable<int> selected) async =>
      _profiles.saveIntakeStep(
        _afterActivities,
        answers: selected.isEmpty
            ? null
            : ProfileDraft(
                preferredActivity: _pick(IntakeMapping.activities, selected.first)),
      );

  /// Het planscherm is bekeken.
  Future<void> savePlanSeen() => _profiles.saveIntakeStep(_afterPlan);

  /// Sluit de onboarding af. Zonder herinnering wordt er niets ingepland.
  Future<void> complete({required bool reminderEnabled, int? reminderMinutes}) async {
    await _profiles.setNotification(
      enabled: reminderEnabled,
      minutes: reminderEnabled ? reminderMinutes : null,
    );
    await _profiles.completeIntake();
  }

  /// Wat er is opgeslagen, en waar de gebruiker verder moet.
  Future<IntakeProgress> load() async {
    final profile = await _profiles.get();
    return progressOf(profile);
  }

  static IntakeProgress progressOf(Profile profile) {
    final completed = profile.intakeCompletedAt != null;
    return IntakeProgress(
      step: completed ? OnboardingStep.done : _stepFor(profile.intakeStep),
      goal: _indexOf(IntakeMapping.goals, profile.primaryGoal),
      obstacle: _indexOf(IntakeMapping.obstacles, profile.obstacle),
      rhythm: _indexOf(IntakeMapping.windDownStartMinutes, profile.bedtimeMinutes),
      activity: _indexOf(IntakeMapping.activities, profile.preferredActivity),
      reminderEnabled: profile.notifyProgramme,
      reminderMinutes: profile.notifyTimeMinutes,
      completed: completed,
    );
  }

  static OnboardingStep _stepFor(int savedStep) => switch (savedStep) {
        <= 0 => OnboardingStep.welcome,
        _afterGoal => OnboardingStep.obstacle,
        _afterObstacle => OnboardingStep.rhythm,
        _afterRhythm => OnboardingStep.activities,
        _afterActivities => OnboardingStep.plan,
        _ => OnboardingStep.reminder,
      };

  static T _pick<T>(List<T> options, int index) {
    if (index < 0 || index >= options.length) {
      throw RangeError.index(index, options, 'optie');
    }
    return options[index];
  }

  static int? _indexOf<T>(List<T> options, T? value) {
    if (value == null) return null;
    final index = options.indexOf(value);
    return index < 0 ? null : index;
  }
}
