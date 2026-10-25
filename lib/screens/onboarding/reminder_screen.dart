import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/data/notifications/notification_permission.dart';
import 'package:rest4more/providers/intake_providers.dart';
import 'package:rest4more/providers/notification_providers.dart';
import 'package:rest4more/providers/plan_providers.dart';
import '../app_shell.dart';
import 'notification_permission_sheets.dart';

class ReminderScreen extends ConsumerStatefulWidget {
  const ReminderScreen({super.key});

  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends ConsumerState<ReminderScreen>
    with WidgetsBindingObserver {
  static const Color background = Color(0xFFFCFAF7);
  static const Color brown = Color(0xFF8B6043);
  static const Color darkBrown = Color(0xFF5A4338);
  static const Color cardBackground = Color(0xFFF5F0E8);
  static const Color yellow = Color(0xFFFFB800);

  bool reminderEnabled = true;
  TimeOfDay reminderTime = const TimeOfDay(
    hour: 22,
    minute: 0,
  );

  /// Bezig met de toestemming, zodat een tweede tik niets dubbel doet.
  bool _asking = false;

  /// De gebruiker is naar de instellingen gestuurd om meldingen aan te zetten.
  bool _sentToSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _showSavedAnswer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Terug uit de instellingen: staan meldingen nu aan, dan gaat de gebruiker
  /// meteen verder met herinnering. Anders blijft het scherm staan en kiest de
  /// gebruiker zelf opnieuw.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_sentToSettings) return;
    _sentToSettings = false;
    _continueIfGranted();
  }

  Future<void> _continueIfGranted() async {
    final status = await _status();
    if (!mounted || status != NotificationPermissionStatus.granted) return;
    await _finish(withReminder: true);
  }

  /// Laat een eerder gegeven antwoord zien.
  Future<void> _showSavedAnswer() async {
    final saved = await ref.read(intakeServiceProvider).load();
    final minutes = saved.reminderMinutes;
    if (!mounted || minutes == null) return;
    setState(() {
      reminderEnabled = saved.reminderEnabled;
      reminderTime = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    });
  }

  /// Done: zonder herinnering meteen verder. Met herinnering eerst de
  /// toestemming voor meldingen, die alleen hier wordt gevraagd.
  Future<void> _onDone() async {
    if (!reminderEnabled) return _finish(withReminder: false);
    if (_asking) return;
    setState(() => _asking = true);
    try {
      final withReminder = await _askPermission();
      if (withReminder != null) await _finish(withReminder: withReminder);
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

  /// True als de herinnering kan worden ingepland, false om zonder herinnering
  /// verder te gaan, null om op dit scherm te blijven.
  ///
  /// Het venster van het systeem verschijnt alleen na de eigen uitleg, en nooit
  /// als het systeem het al heeft geblokkeerd: dan wijzen we naar de
  /// instellingen.
  Future<bool?> _askPermission() async {
    final permission = ref.read(notificationPermissionProvider);
    final time = reminderTime.format(context);
    final status = await _status();
    if (!mounted) return null;

    switch (status) {
      case NotificationPermissionStatus.granted:
        return true;
      case NotificationPermissionStatus.blocked:
        final openSettings = await showNotificationBlocked(context);
        if (openSettings != true) return openSettings;
        _sentToSettings = true;
        final opened = await permission.openSettings().catchError((_) => false);
        if (opened) return null;
        _sentToSettings = false;
        if (mounted) await showNotificationDenied(context);
        return false;
      case NotificationPermissionStatus.notDetermined:
      case NotificationPermissionStatus.denied:
        final proceed = await showNotificationRationale(context, time: time);
        if (proceed != true) return proceed;
        final result = await permission
            .request()
            .catchError((_) => NotificationPermissionStatus.denied);
        if (result == NotificationPermissionStatus.granted) return true;
        if (mounted) await showNotificationDenied(context);
        return false;
    }
  }

  /// De toestand volgens het systeem. Lukt het vragen niet, dan gaan we uit
  /// van "nog niet gevraagd": dan volgt eerst de uitleg.
  Future<NotificationPermissionStatus> _status() => ref
      .read(notificationPermissionProvider)
      .status()
      .catchError((_) => NotificationPermissionStatus.notDetermined);

  /// Sluit de onboarding af en gaat naar de app. [withReminder] is alleen true
  /// als meldingen zijn toegestaan. De herinnering wordt hier alleen bewaard,
  /// het inplannen bij het systeem volgt later.
  Future<void> _finish({required bool withReminder}) async {
    await ref.read(intakeServiceProvider).complete(
          reminderEnabled: withReminder,
          reminderMinutes: reminderTime.hour * 60 + reminderTime.minute,
        );
    ref.invalidate(intakeProgressProvider);
    // Maak het persoonlijke plan. Een fout hier stopt de gebruiker niet: de
    // volgende keer dat de app opent wordt het opnieuw geprobeerd.
    try {
      await ref.read(planServiceProvider).ensurePlan();
    } on Object {
      // zie boven
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AppShell()),
      (route) => false,
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: reminderTime,
    );

    if (picked != null) {
      setState(() {
        reminderTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String time =
        reminderTime.format(context);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back,
                      size: 18,
                      color: brown,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: brown,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE8AE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: brown,
                  size: 28,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'FINAL STEP',
                style: TextStyle(
                  color: brown,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Would you like a\ndaily reminder?',
                style: TextStyle(
                  color: darkBrown,
                  fontSize: 32,
                  height: 1.15,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'A gentle reminder can help you make space '
                'for rest without adding pressure. It is optional: '
                'you can use everything in the app without it.',
                style: TextStyle(
                  color: darkBrown,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily reminder',
                                style: TextStyle(
                                  color: darkBrown,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'One gentle reminder each day',
                                style: TextStyle(
                                  color: brown,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Switch(
                          value: reminderEnabled,
                          activeThumbColor: Colors.white,
                          activeTrackColor: brown,
                          onChanged: (value) {
                            setState(() {
                              reminderEnabled = value;
                            });
                          },
                        ),
                      ],
                    ),

                    if (reminderEnabled) ...[
                      const SizedBox(height: 18),
                      const Divider(),
                      const SizedBox(height: 12),

                      InkWell(
                        onTap: _selectTime,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              color: brown,
                            ),
                            const SizedBox(width: 12),

                            const Expanded(
                              child: Text(
                                'Reminder time',
                                style: TextStyle(
                                  color: darkBrown,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                            Text(
                              time,
                              style: const TextStyle(
                                color: brown,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(width: 4),

                            const Icon(
                              Icons.chevron_right,
                              color: brown,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _asking ? null : _onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brown,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: brown,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed:
                      _asking ? null : () => _finish(withReminder: false),
                  child: const Text(
                    'Maybe later',
                    style: TextStyle(
                      color: brown,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}