import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'daily_reminder_plan.dart';

/// A tap on a notification for a timed session.
abstract class ReminderScheduler {
  /// Daily reminder ID tapped while the app is running.
  Stream<int> get taps;

  /// Session ID from a timer-end notification tapped while the app is running.
  Stream<String> get sessionEndTaps;

  /// Replaces the scheduled daily reminders.
  Future<void> replaceAll(List<DailyReminder> reminders);

  /// Removes daily reminders only, leaving timer notifications scheduled.
  Future<void> cancelDailyReminders();

  /// Removes every notification managed by this plugin.
  Future<void> cancelAll();

  /// ID of a daily reminder that launched the app, or null.
  Future<int?> launchedFrom();

  /// Session ID of a timer-end notification that launched the app, or null.
  Future<String?> launchedFromSessionEnd();

  Future<void> scheduleSessionEnd({
    required String sessionId,
    required String title,
    required String body,
    required DateTime endsAt,
  });

  Future<void> cancelSessionEnd();
}

class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _sessionEndNotificationId = 900000001;
  static const _dailyTimerNotificationId = 900000002;

  static const _sessionPayloadPrefix = 'session-end:';
  static const _dailyTimerPayloadPrefix = 'daily-timer:';

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<int>.broadcast();
  final _sessionEndTaps = StreamController<String>.broadcast();

  Future<void>? _ready;

  static const _dailyReminderDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_step',
      'Daily step reminder',
      channelDescription: 'A gentle reminder for your daily step.',
    ),
    iOS: DarwinNotificationDetails(),
  );

  static const _sessionEndDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'quiet_session_end',
      'Quiet session finished',
      channelDescription: 'A quiet reminder when a timed session ends.',
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
      enableVibration: false,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: false,
      presentBanner: false,
      presentList: true,
      presentSound: false,
      presentBadge: false,
      interruptionLevel: InterruptionLevel.passive,
    ),
  );

  @override
  Stream<int> get taps => _taps.stream;

  @override
  Stream<String> get sessionEndTaps => _sessionEndTaps.stream;

  Future<void> _init() => _ready ??= () async {
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is requested separately, when the user chooses it.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.startsWith(_sessionPayloadPrefix)) {
          _sessionEndTaps.add(payload.substring(_sessionPayloadPrefix.length));
          return;
        }

        final id = response.id;
        if (id != null) _taps.add(id);
      },
    );
  }();

  /// Refresh the device time zone before scheduling local notifications.
  Future<void> _useDeviceTimeZone() async {
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Object {
      // UTC remains available if the device time zone cannot be read.
    }
  }

  @override
  Future<void> replaceAll(List<DailyReminder> reminders) async {
    await _init();
    await _useDeviceTimeZone();
    await cancelDailyReminders();

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
        notificationDetails: _dailyReminderDetails,
        androidScheduleMode: mode,
        title: reminder.title,
        body: reminder.body,
        payload: reminder.programmeDayId,
      );
    }
  }

  @override
  Future<void> scheduleSessionEnd({
    required String sessionId,
    required String title,
    required String body,
    required DateTime endsAt,
  }) async {
    await _init();
    await _useDeviceTimeZone();

    // Only one Focus or Reading session can be active at a time.
    await _plugin.cancel(id: _sessionEndNotificationId);

    if (!endsAt.isAfter(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id: _sessionEndNotificationId,
      scheduledDate: tz.TZDateTime.from(endsAt, tz.local),
      notificationDetails: _sessionEndDetails,
      androidScheduleMode: await _scheduleMode(),
      title: title,
      body: body,
      payload: '$_sessionPayloadPrefix$sessionId',
    );
  }

  @override
  Future<void> cancelSessionEnd() async {
    await _init();
    await _plugin.cancel(id: _sessionEndNotificationId);
  }

  /// Android can use exact delivery when allowed; otherwise use inexact
  /// delivery without requesting exact-alarm permission.
  Future<AndroidScheduleMode> _scheduleMode() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return AndroidScheduleMode.exactAllowWhileIdle;

    final exact = await android.canScheduleExactNotifications() ?? false;
    return exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  bool _isTimerNotification(int id, String? payload) {
    return id == _sessionEndNotificationId ||
        id == _dailyTimerNotificationId ||
        (payload?.startsWith(_sessionPayloadPrefix) ?? false) ||
        (payload?.startsWith(_dailyTimerPayloadPrefix) ?? false);
  }

  @override
  Future<void> cancelDailyReminders() async {
    await _init();

    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (!_isTimerNotification(request.id, request.payload)) {
        await _plugin.cancel(id: request.id);
      }
    }

    // Also clear daily reminders already delivered to Notification Center,
    // while preserving timer notifications.
    try {
      final active = await _plugin.getActiveNotifications();
      for (final notification in active) {
        final id = notification.id;
        if (id != null && !_isTimerNotification(id, null)) {
          await _plugin.cancel(id: id);
        }
      }
    } on Object {
      // Pending reminders were still cleared if active notifications aren't
      // supported by the current platform.
    }
  }

  /// Explicitly cancels every notification managed by this plugin.
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

    final response = details.notificationResponse;
    if (response?.payload?.startsWith(_sessionPayloadPrefix) ?? false) {
      return null;
    }
    if (response?.payload?.startsWith(_dailyTimerPayloadPrefix) ?? false) {
      return null;
    }
    return response?.id;
  }

  @override
  Future<String?> launchedFromSessionEnd() async {
    await _init();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;

    final payload = details.notificationResponse?.payload;
    if (payload == null || !payload.startsWith(_sessionPayloadPrefix)) {
      return null;
    }

    return payload.substring(_sessionPayloadPrefix.length);
  }
}
