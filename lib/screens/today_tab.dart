import 'package:rest4more/l10n/app_localizations.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/programme/today_plan.dart';
import 'package:rest4more/providers/notification_providers.dart';
import 'package:rest4more/providers/plan_providers.dart';
import 'package:rest4more/providers/repository_providers.dart';
import 'daily_timer_screen.dart';

import 'today_screen.dart';

/// Het Today-scherm gevuld met de eerstvolgende stap uit het persoonlijke plan.
///
/// Dag voor dag: de stap die je nog niet hebt gedaan. Een stap afronden schuift
/// het plan door, ook na dagen niets doen.
class TodayTab extends ConsumerStatefulWidget {
  const TodayTab({super.key, this.onStartStep});

  /// Hier komt later de echte sessie (timer, blokkeren). Wordt aangeroepen als
  /// de gebruiker de stap start.
  final ValueChanged<int>? onStartStep;

  @override
  ConsumerState<TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends ConsumerState<TodayTab>
    with WidgetsBindingObserver {
  String? _offeredFor;
  Timer? _midnight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnight();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnight?.cancel();
    super.dispose();
  }

  /// Een nieuwe dag brengt de volgende stap. Ook als de app open blijft staan.
  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1, 0, 0, 1);
    _midnight = Timer(next.difference(now), () {
      if (!mounted) return;
      ref.invalidate(todayPlanProvider);
      _scheduleMidnight();
    });
  }

  /// Terug in de app na een nacht in de achtergrond: opnieuw bepalen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(todayPlanProvider);
      _scheduleMidnight();
    }
  }

  /// Een stap die wordt getoond is aangeboden. Eenmalig per stap.
  void _offer(TodayPlan today) {
    if (_offeredFor == today.dayId || today.status != DayStatus.planned) return;
    _offeredFor = today.dayId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(programmeRepositoryProvider).markOffered(today.dayId);
    });
  }

    Future<void> _start(TodayPlan today, int minutes) async {
    final programme = ref.read(programmeRepositoryProvider);

    await programme.markOpened(today.dayId);
    if (!mounted) return;

    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => DailyTimerScreen(minutes: minutes),
      ),
    );

    if (done != true || !mounted) return;

    await programme.markCompleted(today.dayId);
    // Geen herinnering meer voor vandaag; de volgende noemt de nieuwe stap.
    ref.read(reminderServiceProvider).sync();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).dayIsDone(today.day))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(todayPlanProvider);
    return plan.when(
      loading: () => const Scaffold(
        backgroundColor: RestPalette.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      // Een leesfout of nog geen plan: het scherm met zijn standaardtekst.
      error: (_, _) => TodayScreen(onStartStep: widget.onStartStep),
      data: (today) {
        if (today == null) return TodayScreen(onStartStep: widget.onStartStep);
        if (today.finished) return _PlanFinished(totalDays: today.totalDays);
        if (today.waitingForTomorrow) {
          return _DoneForToday(day: today.day);
        }
        _offer(today);
        return TodayScreen(
          // Nieuwe stap, nieuwe staat.
          key: ValueKey(today.dayId),
          day: today.day,
          totalDays: today.totalDays,
          minutes: today.minutes,
          smallerMinutes: today.smallerMinutes,
          greeting: greetingFor(DateTime.now(), AppLocalizations.of(context)),
          invitation: today.title,
          description: today.action,
          explanation: today.explanation,
          onStartStep: (minutes) => _start(today, minutes),
          onMakeSmaller: (_) => ref
              .read(programmeRepositoryProvider)
              .setSize(today.dayId, DaySize.smaller),
        );
      },
    );
  }
}

/// Vraagt of de stap gedaan is. Tijdelijk tot er een echte sessie is: dan
/// rondt de sessie de stap zelf af.


/// De stap van vandaag is gedaan. De volgende is er morgen.
class _DoneForToday extends StatelessWidget {
  const _DoneForToday({required this.day});

  /// De volgende stap.
  final int day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RestPalette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).todaysStepDone, style: RestType.serif(34)),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).dayReadyTomorrow(day),
                style: RestType.sans(16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alle stappen zijn gedaan. Het eigen ritme gaat verder.
class _PlanFinished extends StatelessWidget {
  const _PlanFinished({required this.totalDays});

  final int totalDays;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RestPalette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).allStepsDone(totalDays), style: RestType.serif(34)),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).ownRoutineContinues,
                style: RestType.sans(16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
