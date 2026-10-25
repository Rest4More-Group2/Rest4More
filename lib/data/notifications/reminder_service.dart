import '../repositories/profile_repository.dart';
import 'notification_permission.dart';

/// Houdt de herinneringskeuze in het profiel gelijk aan de toestemming van het
/// systeem.
class ReminderService {
  ReminderService(this._profiles, this._permission);

  final ProfileRepository _profiles;
  final NotificationPermission _permission;

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
}
