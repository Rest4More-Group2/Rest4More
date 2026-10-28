import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'daily_reminder_plan.dart';

/// Zet herinneringen klaar bij het besturingssysteem. Vraagt nooit om
/// toestemming: dat doet alleen [NotificationPermission].
abstract class ReminderScheduler {
  /// Haalt alle geplande en getoonde herinneringen weg en zet [reminders]
  /// klaar.
  Future<void> replaceAll(List<DailyReminder> reminders);

  Future<void> cancelAll();

  /// De id van een herinnering waarop is getikt terwijl de app draaide.
  Stream<int> get taps;

  /// De id van de herinnering waarmee de app is geopend, of null.
  Future<int?> launchedFrom();
}

class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<int>.broadcast();
  Future<void>? _ready;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_step',
      'Daily step reminder',
      channelDescription: 'A gentle reminder for your daily step.',
    ),
    iOS: DarwinNotificationDetails(),
  );

  @override
  Stream<int> get taps => _taps.stream;

  Future<void> _init() => _ready ??= () async {
        tz_data.initializeTimeZones();
        await _plugin.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            // Niet vragen bij het opstarten: dat gebeurt alleen als de
            // gebruiker herinneringen aanzet.
            iOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestSoundPermission: false,
              requestBadgePermission: false,
            ),
          ),
          onDidReceiveNotificationResponse: (response) {
            final id = response.id;
            if (id != null) _taps.add(id);
          },
        );
      }();

  /// De tijdzone van het toestel, elke keer opnieuw: na een reis staan de
  /// herinneringen dan weer op de gekozen kloktijd.
  Future<void> _useDeviceTimeZone() async {
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Object {
      // Onbekende zone: UTC blijft staan, beter dan geen herinnering.
    }
  }

  @override
  Future<void> replaceAll(List<DailyReminder> reminders) async {
    await _init();
    await _useDeviceTimeZone();
    await _plugin.cancelAll();
    final mode = await _scheduleMode();
    final now = tz.TZDateTime.now(tz.local);
    for (final reminder in reminders) {
      final at = tz.TZDateTime(
        tz.local,
        reminder.date.year,
        reminder.date.month,
        reminder.date.day,
        reminder.minutes ~/ 60,
        reminder.minutes % 60,
      );
      if (!at.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        id: reminder.id,
        scheduledDate: at,
        notificationDetails: _details,
        androidScheduleMode: mode,
        title: reminder.title,
        body: reminder.body,
        payload: reminder.programmeDayId,
      );
    }
  }

  /// Precies op tijd als Android dat toestaat. Anders iets ruimer: daar vragen
  /// we geen extra toestemming voor, de melding kan dan een paar minuten later
  /// komen.
  Future<AndroidScheduleMode> _scheduleMode() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return AndroidScheduleMode.exactAllowWhileIdle;
    final exact = await android.canScheduleExactNotifications() ?? false;
    return exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  @override
  Future<void> cancelAll() async {
    await _init();
    await _plugin.cancelAll();
  }

  @override
  Future<int?> launchedFrom() async {
    await _init();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.id;
  }
}
