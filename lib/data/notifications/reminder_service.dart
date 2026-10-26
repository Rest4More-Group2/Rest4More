import '../database/enums.dart';
import '../repositories/local_notification_store.dart';
import '../repositories/profile_repository.dart';
import '../repositories/programme_repository.dart';
import 'daily_reminder_plan.dart';
import 'notification_permission.dart';
import 'reminder_scheduler.dart';

/// Houdt de herinneringskeuze in het profiel gelijk aan de toestemming van het
/// systeem, en de geplande herinneringen gelijk aan die keuze en het plan.
class ReminderService {
  ReminderService(
    this._profiles,
    this._permission, {
    required this._programme,
    required this._scheduler,
    required this._store,
    this._now = DateTime.now,
  });

  final ProfileRepository _profiles;
  final NotificationPermission _permission;
  final ProgrammeRepository _programme;
  final ReminderScheduler _scheduler;
  final LocalNotificationStore _store;
  final DateTime Function() _now;

  /// Een planning tegelijk, in volgorde van aanvragen.
  Future<void> _running = Future.value();

  /// Zet de herinnering uit als de gebruiker meldingen intussen heeft
  /// uitgezet in de instellingen van het toestel. De gekozen tijd blijft
  /// bewaard. Vraagt zelf nooit om toestemming.
  Future<void> reconcileWithPermission() async {
    final NotificationPermissionStatus status;
    try {
      status = await _permission.status();
    } on Object {
      // Onbekend is niet hetzelfde als geweigerd: laat de keuze staan.
      return;
    }
    if (status == NotificationPermissionStatus.granted) return;
    final profile = await _profiles.get();
    if (!profile.notifyProgramme) return;
    await _profiles.setNotification(enabled: false);
  }

  /// Zet de herinneringen voor de komende dagen klaar, of haalt ze weg als
  /// ze niet meer horen: herinnering uit, geen toestemming, plan gepauzeerd,
  /// gestopt of klaar. Veilig om vaak aan te roepen. Een fout wordt
  /// ingeslikt: de app werkt ook zonder herinneringen.
  Future<void> sync() => _running = _running.then((_) async {
        try {
          await _sync();
        } on Object {
          // De volgende keer dat de app opent wordt het opnieuw geprobeerd.
        }
      });

  Future<void> _sync() async {
    final reminders = await _plan();
    if (reminders == null) return;
    if (reminders.isEmpty) {
      await _scheduler.cancelAll();
      await _store.cancelAll();
      return;
    }
    await _scheduler.replaceAll(reminders);
    await _store.replaceAll([
      for (final r in reminders)
        PlannedEntry(
          osNotificationId: r.id,
          kind: NotificationKind.programme,
          firesOn: r.date,
          firesAtMinutes: r.minutes,
          programmeDayId: r.programmeDayId,
        ),
    ]);
  }

  /// Null als de toestemming niet te lezen is: dan blijft alles staan.
  Future<List<DailyReminder>?> _plan() async {
    final profile = await _profiles.get();
    final minutes = profile.notifyTimeMinutes;
    if (!profile.notifyProgramme || minutes == null) return const [];

    final NotificationPermissionStatus status;
    try {
      status = await _permission.status();
    } on Object {
      return null;
    }
    if (status != NotificationPermissionStatus.granted) return const [];

    final enrollment = await _programme.activeEnrollment();
    if (enrollment == null || enrollment.status != EnrollmentStatus.active) {
      return const [];
    }
    final days = await _programme.days(enrollment.id);
    return planDailyReminders(days: days, minutes: minutes, now: _now());
  }

  /// Een herinnering is geopend.
  Future<void> markOpened(int osNotificationId) async {
    try {
      await _store.markOpenedByOsId(osNotificationId);
    } on Object {
      // Alleen boekhouding.
    }
  }
}
