import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/data/programme/today_plan.dart';
import 'package:rest4more/providers/plan_providers.dart';

import 'today_screen.dart';

/// Het Today-scherm gevuld met de dag uit het persoonlijke plan.
class TodayTab extends ConsumerWidget {
  const TodayTab({super.key, this.onStartStep});

  final ValueChanged<int>? onStartStep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(todayPlanProvider);
    return plan.when(
      loading: () => const Scaffold(
        backgroundColor: RestPalette.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      // Een leesfout of nog geen plan: het scherm met zijn standaardtekst.
      error: (_, _) => TodayScreen(onStartStep: onStartStep),
      data: (today) {
        if (today == null) return TodayScreen(onStartStep: onStartStep);
        return TodayScreen(
          // Nieuwe dag, nieuwe staat.
          key: ValueKey(today.dayId),
          day: today.day,
          totalDays: today.totalDays,
          minutes: today.minutes,
          smallerMinutes: today.smallerMinutes,
          greeting: greetingFor(DateTime.now()),
          invitation: today.title,
          description: today.action,
          explanation: today.explanation,
          onStartStep: onStartStep,
        );
      },
    );
  }
}
