import '../database/app_database.dart';
import '../database/enums.dart';
import '../repositories/profile_repository.dart';
import '../repositories/programme_repository.dart';
import 'content_catalog.dart';
import 'plan_input.dart';
import 'plan_scheduler.dart';
import 'plan_selector.dart';

/// Maakt het persoonlijke plan van 14 dagen na de onboarding en bewaart het in
/// de database: een deelname met de antwoorden en veertien dagen met de
/// uitgewerkte inhoud van elke dag (zodat later te zien is wat de gebruiker
/// kreeg, ook als de inhoud verandert).
class PlanService {
  PlanService(this._db, this._loadCatalog, {this._now = DateTime.now});

  final AppDatabase _db;
  final Future<ContentCatalog> Function() _loadCatalog;
  final DateTime Function() _now;

  /// Versie van de regels die het plan samenstellen. Wordt bij de deelname
  /// bewaard. Verhoog dit als de selectie verandert.
  static const rulesVersion = 1;

  /// Maakt het plan als de gebruiker er nog geen heeft. Doet niets als de
  /// onboarding niet af is, er geen doel is gekozen, of er al een deelname
  /// bestaat. Geeft terug of er nu een plan is gemaakt.
  Future<bool> ensurePlan() async {
    final profiles = ProfileRepository(_db, now: _now);
    final profile = await profiles.get();
    if (profile.intakeCompletedAt == null) return false;
    if (await _hasEnrollment()) return false;

    final input = PlanInput.fromProfile(profile);
    if (input == null) return false;

    final catalog = await _loadCatalog();
    final days = selectPlan(input, catalog);

    final now = _now();
    final start = planStartDate(now: now, reminderMinutes: input.reminderMinutes);
    final dates = planDates(start);

    final programme = ProgrammeRepository(_db, now: _now);
    await _db.transaction(() async {
      final enrollment = await programme.enroll(
        contentVersion: catalog.version,
        selection: {...input.toJson(), 'rules_version': rulesVersion},
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
    return true;
  }

  Future<bool> _hasEnrollment() async {
    final rows = await _db
        .customSelect(
            'SELECT 1 FROM programme_enrollments WHERE deleted_at IS NULL LIMIT 1')
        .get();
    return rows.isNotEmpty;
  }
}
