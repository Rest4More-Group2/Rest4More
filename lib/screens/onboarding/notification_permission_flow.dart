import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/data/notifications/notification_permission.dart';
import 'package:rest4more/providers/notification_providers.dart';

import 'notification_permission_sheets.dart';

/// Hoe het vragen om toestemming voor herinneringen afliep.
enum ReminderPermissionOutcome {
  /// Meldingen mogen: de herinnering kan aan.
  granted,

  /// De gebruiker gaat verder zonder herinnering.
  declined,

  /// Venster weggeveegd: niets gekozen, blijf op het scherm.
  dismissed,

  /// Naar de instellingen van het toestel gestuurd. Kijk bij terugkomst met
  /// [reminderPermissionStatus] of meldingen nu mogen.
  sentToSettings,
}

/// Vraagt toestemming voor meldingen nadat de gebruiker herinneringen heeft
/// aangezet. Het venster van het systeem verschijnt alleen na de eigen uitleg,
/// en nooit als het systeem het al heeft geblokkeerd: dan wijzen we naar de
/// instellingen. [time] staat in de uitleg.
Future<ReminderPermissionOutcome> askReminderPermission(
  BuildContext context,
  WidgetRef ref, {
  required String time,
}) async {
  final permission = ref.read(notificationPermissionProvider);
  final status = await reminderPermissionStatus(ref);
  if (!context.mounted) return ReminderPermissionOutcome.dismissed;

  switch (status) {
    case NotificationPermissionStatus.granted:
      return ReminderPermissionOutcome.granted;
    case NotificationPermissionStatus.blocked:
      final openSettings = await showNotificationBlocked(context);
      if (openSettings == null) return ReminderPermissionOutcome.dismissed;
      if (!openSettings) return ReminderPermissionOutcome.declined;
      final opened = await permission.openSettings().catchError((_) => false);
      if (opened) return ReminderPermissionOutcome.sentToSettings;
      if (context.mounted) await showNotificationDenied(context);
      return ReminderPermissionOutcome.declined;
    case NotificationPermissionStatus.notDetermined:
    case NotificationPermissionStatus.denied:
      final proceed = await showNotificationRationale(context, time: time);
      if (proceed == null) return ReminderPermissionOutcome.dismissed;
      if (!proceed) return ReminderPermissionOutcome.declined;
      final result = await permission
          .request()
          .catchError((_) => NotificationPermissionStatus.denied);
      if (result == NotificationPermissionStatus.granted) {
        return ReminderPermissionOutcome.granted;
      }
      if (context.mounted) await showNotificationDenied(context);
      return ReminderPermissionOutcome.declined;
  }
}

/// De toestand volgens het systeem. Lukt het vragen niet, dan gaan we uit van
/// "nog niet gevraagd": dan volgt eerst de uitleg.
Future<NotificationPermissionStatus> reminderPermissionStatus(WidgetRef ref) =>
    ref
        .read(notificationPermissionProvider)
        .status()
        .catchError((_) => NotificationPermissionStatus.notDetermined);
