import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/data/moments/moment_plans.dart';
import 'package:rest4more/data/moments/moment_profiles.dart';
import 'package:rest4more/data/moments/moment_schedule.dart';
import 'package:rest4more/data/notifications/reminder_scheduler.dart';
import 'package:rest4more/providers/notification_providers.dart';

import 'manual_routine_screen.dart';
import 'moment_timer_display.dart';
import 'moments_form_widgets.dart';
import 'today_screen.dart' show RestPalette, RestType;

class EveningReminderScreen extends ConsumerStatefulWidget {
  const EveningReminderScreen({
    super.key,
    required this.tap,
    required this.plan,
  });

  final EveningReminderTap tap;
  final EveningPlan plan;

  @override
  ConsumerState<EveningReminderScreen> createState() =>
      _EveningReminderScreenState();
}

class _EveningReminderScreenState extends ConsumerState<EveningReminderScreen>
    with WidgetsBindingObserver {
  static const _postponeDuration = Duration(minutes: 15);

  Timer? _ticker;
  DateTime _now = DateTime.now();
  bool _busy = false;

  bool get _isDutch =>
      Localizations.localeOf(context).languageCode == 'nl';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    if (mounted) setState(() => _now = DateTime.now());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      await action();
    } catch (error) {
      debugPrint('[evening-reminder] $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isDutch
                ? 'Dat is niet gelukt. Probeer het opnieuw.'
                : 'That didn’t work. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() async {
    final plan = widget.plan;
    await ref
        .read(reminderSchedulerProvider)
        .cancelEveningReminders(widget.tap.eveningDate);

    if (!mounted) return;

    // Use the same start flow as "Start evening now" in SavedEveningScreen.
    await Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (_) => ManualRoutineScreen(
          kind: MomentKind.evening,
          minutes: totalMinutes(plan.steps),
          strict: plan.end == EveningEnd.atNextScan,
        ),
      ),
    );
  }

  Future<void> _skip() async {
    await ref
        .read(reminderSchedulerProvider)
        .cancelEveningReminders(widget.tap.eveningDate);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isDutch
              ? 'Je hebt deze avondroutine overgeslagen.'
              : 'You skipped this evening’s routine.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _postpone() async {
    final now = DateTime.now();
    final previousStart = widget.tap.startsAt;
    final base = previousStart.isAfter(now) ? previousStart : now;
    final newStart = base.add(_postponeDuration);
    final graceMinutes = widget.plan.secondReminderMinutes;
    final dutch = _isDutch;
    final time = formatTime(newStart);

    // Reuse this evening's two notification IDs. The user's explicit
    // postpone action requests a reminder when the new start time arrives.
    await ref.read(reminderSchedulerProvider).scheduleEveningReminders(
      eveningDate: widget.tap.eveningDate,
      startsAt: newStart,
      headsUpAt: newStart,
      followUpAt: graceMinutes == 0
          ? null
          : newStart.add(Duration(minutes: graceMinutes)),
      headsUpTitle: dutch
          ? 'Tijd voor je avondroutine'
          : 'Time for your evening routine',
      headsUpBody: dutch
          ? 'Tik om je uitgestelde routine te starten.'
          : 'Tap to start your postponed routine.',
      followUpTitle: dutch
          ? 'Klaar voor je avondroutine?'
          : 'Ready to start your evening routine?',
      followUpBody: dutch
          ? 'Tik om je avondroutine te openen.'
          : 'Tap to open your evening routine.',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          dutch
              ? 'Je avondroutine is uitgesteld tot $time.'
              : 'Evening routine postponed until $time.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dutch = _isDutch;
    final startsAt = widget.tap.startsAt;
    final remaining = startsAt.difference(_now);
    final due = !remaining.isNegative && remaining == Duration.zero ||
        remaining.isNegative;

    // Round up so the clock shows 00:01 during the last fraction of a second.
    final secondsLeft = due ? 0 : (remaining.inMicroseconds + 999999) ~/ 1000000;
    final clock = formatClock(Duration(seconds: secondsLeft));
    final leadSeconds = widget.plan.windDownLeadMinutes * 60;
    final progress = due || leadSeconds <= 0
        ? 1.0
        : (1 - secondsLeft / leadSeconds).clamp(0.0, 1.0).toDouble();

    final startTime = formatTime(startsAt);
    final title = dutch ? 'Je avondroutine' : 'Your evening routine';
    final status = due
        ? (dutch ? 'Tijd om te beginnen' : 'Time to start')
        : (dutch ? 'Begint om $startTime' : 'Starts at $startTime');

    return Scaffold(
      backgroundColor: RestPalette.background,
      appBar: AppBar(backgroundColor: RestPalette.background),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                Text(title, style: RestType.serif(40)),
                const SizedBox(height: 32),
                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: RestType.sans(18, weight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                MomentTimerDisplay(
                  clockText: clock,
                  semanticLabel: due
                      ? status
                      : (dutch
                            ? 'Nog $clock tot je avondroutine'
                            : '$clock until your evening routine'),
                  progress: progress,
                  barColor: RestPalette.primary,
                ),
                const SizedBox(height: 32),
                MomentPrimaryButton(
                  label: dutch ? 'Nu starten' : 'Start now',
                  onPressed: _busy ? null : () => _perform(_start),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy ? null : () => _perform(_postpone),
                  child: Text(dutch ? '15 min uitstellen' : 'Postpone 15 min'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _perform(_skip),
                  child: Text(dutch ? 'Vanavond overslaan' : 'Skip tonight'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}