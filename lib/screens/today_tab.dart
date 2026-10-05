import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/programme/today_plan.dart';
import 'package:rest4more/providers/plan_providers.dart';
import 'package:rest4more/providers/repository_providers.dart';

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

class _TodayTabState extends ConsumerState<TodayTab> {
  String? _offeredFor;

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
    widget.onStartStep?.call(minutes);
    if (!mounted) return;

    final done = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: RestPalette.background,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ConfirmStep(today: today, minutes: minutes),
    );
    if (done != true || !mounted) return;

    await programme.markCompleted(today.dayId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Day ${today.day} is done.')),
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
        _offer(today);
        return TodayScreen(
          // Nieuwe stap, nieuwe staat.
          key: ValueKey(today.dayId),
          day: today.day,
          totalDays: today.totalDays,
          minutes: today.minutes,
          smallerMinutes: today.smallerMinutes,
          greeting: greetingFor(DateTime.now()),
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
class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({required this.today, required this.minutes});

  final TodayPlan today;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Day ${today.day}: ${today.title}', style: RestType.serif(28)),
            const SizedBox(height: 12),
            Text(today.action, style: RestType.sans(16)),
            const SizedBox(height: 8),
            Text('Take about $minutes minutes, away from your screen.',
                style: RestType.sans(14, color: RestPalette.accent)),
            const SizedBox(height: 24),
            RestActionButton(
              label: 'Mark as done',
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 12),
            RestActionButton(
              label: 'Not yet',
              outlined: true,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
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
              Text('All $totalDays steps are done', style: RestType.serif(34)),
              const SizedBox(height: 12),
              Text(
                'Your own routine continues. Keep the phone location, the '
                'phone-away moment and the activity that fitted you best.',
                style: RestType.sans(16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
