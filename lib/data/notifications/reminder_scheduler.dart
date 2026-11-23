import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'daily_reminder_plan.dart';

enum EveningReminderKind { headsUp, followUp }

/// Identifies the evening and the scheduled start when a reminder is tapped.
class EveningReminderTap {
  const EveningReminderTap({
    required this.eveningDate,
    required this.startsAt,
    required this.kind,
  });

  /// The calendar day the evening belongs to, including for late bedtimes.
  final DateTime eveningDate;
  final DateTime startsAt;
  final EveningReminderKind kind;

  static const prefix = 'evening-routine:';

  String get payload {
    final date = DateTime.utc(
      eveningDate.year,
      eveningDate.month,
      eveningDate.day,
    );

    return '$prefix${date.millisecondsSinceEpoch}:'
        '${startsAt.millisecondsSinceEpoch}:${kind.name}';
  }

  static EveningReminderTap? parse(String? payload) {
    if (payload == null || !payload.startsWith(prefix)) return null;

    final parts = payload.substring(prefix.length).split(':');
    if (parts.length != 3) return null;

    final dayMillis = int.tryParse(parts[0]);
    final startMillis = int.tryParse(parts[1]);
    final kind = switch (parts[2]) {
      'headsUp' => EveningReminderKind.headsUp,
      'followUp' => EveningReminderKind.followUp,
      _ => null,
    };

    if (dayMillis == null || startMillis == null || kind == null) {
      return null;
    }

    try {
      final day = DateTime.fromMillisecondsSinceEpoch(dayMillis, isUtc: true);
      return EveningReminderTap(
        eveningDate: DateTime(day.year, day.month, day.day),
        startsAt: DateTime.fromMillisecondsSinceEpoch(startMillis),
        kind: kind,
      );
    } on ArgumentError {
      return null;
    }
  }
}

abstract class ReminderScheduler {
  Stream<int> get taps;
  Stream<String> get sessionEndTaps;
  Stream<EveningReminderTap> get eveningReminderTaps;

  Future<void> replaceAll(List<DailyReminder> reminders);
  Future<void> cancelDailyReminders();
  Future<void> cancelAll();

  Future<int?> launchedFrom();
  Future<String?> launchedFromSessionEnd();
  Future<EveningReminderTap?> launchedFromEveningReminder();

  Future<void> scheduleSessionEnd({
    required String sessionId,
    required String title,
    required String body,
    required DateTime endsAt,
  });

  Future<void> cancelSessionEnd();

  /// Replaces the reminders for one evening. Pass null for followUpAt
  /// when the user selects Off.
  Future<void> scheduleEveningReminders({
    required DateTime eveningDate,
    required DateTime startsAt,
    required DateTime headsUpAt,
    required DateTime? followUpAt,
    required String headsUpTitle,
    required String headsUpBody,
    required String followUpTitle,
    required String followUpBody,
  });

  Future<void> cancelEveningReminders(DateTime eveningDate);
}

class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _sessionEndNotificationId = 900000001;
  static const _dailyTimerNotificationId = 900000002;

  // Two IDs per evening: one for the heads-up and one for the follow-up.
  static const _eveningIdBase = 1000000000;
  static const _eveningIdLimit = 1100000000;

  static const _sessionPayloadPrefix = 'session-end:';
  static const _dailyTimerPayloadPrefix = 'daily-timer:';

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<int>.broadcast();
  final _sessionEndTaps = StreamController<String>.broadcast();
  final _eveningReminderTaps =
      StreamController<EveningReminderTap>.broadcast();

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

  static const _eveningReminderDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'evening_routine_reminders',
      'Evening routine reminders',
      channelDescription: 'Heads-up and follow-up for your evening routine.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
      presentBadge: false,
      interruptionLevel: InterruptionLevel.active,
    ),
  );

  @override
  Stream<int> get taps => _taps.stream;

  @override
  Stream<String> get sessionEndTaps => _sessionEndTaps.stream;

  @override
  Stream<EveningReminderTap> get eveningReminderTaps =>
      _eveningReminderTaps.stream;

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

        if (payload != null && payload.startsWith(EveningReminderTap.prefix)) {
          final tap = EveningReminderTap.parse(payload);
          if (tap != null) _eveningReminderTaps.add(tap);
          return;
        }

        if (payload != null && payload.startsWith(_sessionPayloadPrefix)) {
          _sessionEndTaps.add(payload.substring(_sessionPayloadPrefix.length));
          return;
        }

        final id = response.id;
        if (id != null) _taps.add(id);
      },
    );
  }();

  Future<void> _useDeviceTimeZone() async {
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Object {
      // Keep the current timezone if the device timezone cannot be read.
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

  int _eveningId(DateTime eveningDate, EveningReminderKind kind) {
    // UTC calendar dates keep the ID stable across daylight-saving changes.
    final day = DateTime.utc(
      eveningDate.year,
      eveningDate.month,
      eveningDate.day,
    ).difference(DateTime.utc(2000)).inDays;

    return _eveningIdBase + day * 2 + kind.index;
  }

  @override
  Future<void> scheduleEveningReminders({
    required DateTime eveningDate,
    required DateTime startsAt,
    required DateTime headsUpAt,
    required DateTime? followUpAt,
    required String headsUpTitle,
    required String headsUpBody,
    required String followUpTitle,
    required String followUpBody,
  }) async {
    await _init();
    await _useDeviceTimeZone();

    final mode = await _scheduleMode();

    Future<void> replaceReminder({
      required EveningReminderKind kind,
      required DateTime? at,
      required String title,
      required String body,
    }) async {
      final id = _eveningId(eveningDate, kind);

      // This also clears an old follow-up when the user switches it off.
      if (at == null || !at.isAfter(DateTime.now())) {
        await _plugin.cancel(id: id);
        return;
      }

      final tap = EveningReminderTap(
        eveningDate: eveningDate,
        startsAt: startsAt,
        kind: kind,
      );

      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: _eveningReminderDetails,
        androidScheduleMode: mode,
        title: title,
        body: body,
        payload: tap.payload,
      );
    }

    await replaceReminder(
      kind: EveningReminderKind.headsUp,
      at: headsUpAt,
      title: headsUpTitle,
      body: headsUpBody,
    );

    await replaceReminder(
      kind: EveningReminderKind.followUp,
      at: followUpAt,
      title: followUpTitle,
      body: followUpBody,
    );
  }

  @override
  Future<void> cancelEveningReminders(DateTime eveningDate) async {
    await _init();
    for (final kind in EveningReminderKind.values) {
      await _plugin.cancel(id: _eveningId(eveningDate, kind));
    }
  }

  Future<AndroidScheduleMode> _scheduleMode() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android == null) return AndroidScheduleMode.exactAllowWhileIdle;

    final exact = await android.canScheduleExactNotifications() ?? false;
    return exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  bool _isNonDailyNotification(int id, String? payload) {
    return id == _sessionEndNotificationId ||
        id == _dailyTimerNotificationId ||
        (id >= _eveningIdBase && id < _eveningIdLimit) ||
        (payload?.startsWith(_sessionPayloadPrefix) ?? false) ||
        (payload?.startsWith(_dailyTimerPayloadPrefix) ?? false) ||
        (payload?.startsWith(EveningReminderTap.prefix) ?? false);
  }

  @override
  Future<void> cancelDailyReminders() async {
    await _init();

    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (!_isNonDailyNotification(request.id, request.payload)) {
        await _plugin.cancel(id: request.id);
      }
    }

    // Active notifications may only expose an ID, so the reserved evening
    // ID range also protects reminders already in the notification center.
    try {
      final active = await _plugin.getActiveNotifications();
      for (final notification in active) {
        final id = notification.id;
        if (id != null && !_isNonDailyNotification(id, null)) {
          await _plugin.cancel(id: id);
        }
      }
    } on Object {
      // Some platforms only support querying pending notifications.
    }
  }

  @override
  Future<void> cancelAll() async {
    await _init();
    await _plugin.cancelAll();
  }

  Future<NotificationResponse?> _launchResponse() async {
    await _init();
    final details = await _plugin.getNotificationAppLaunchDetails();

    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse;
  }

  @override
  Future<int?> launchedFrom() async {
    final response = await _launchResponse();
    final id = response?.id;
    if (id == null || _isNonDailyNotification(id, response?.payload)) {
      return null;
    }
    return id;
  }

  @override
  Future<String?> launchedFromSessionEnd() async {
    final response = await _launchResponse();
    final payload = response?.payload;

    if (payload == null || !payload.startsWith(_sessionPayloadPrefix)) {
      return null;
    }
    return payload.substring(_sessionPayloadPrefix.length);
  }

  @override
  Future<EveningReminderTap?> launchedFromEveningReminder() async {
    final response = await _launchResponse();
    return EveningReminderTap.parse(response?.payload);
  }
}