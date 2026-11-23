import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/progress/progress_analytics.dart';
import 'package:rest4more/data/progress/progress_summary.dart';
import 'package:rest4more/l10n/app_localizations.dart';
import 'package:rest4more/providers/notification_providers.dart';
import 'package:rest4more/providers/progress_providers.dart';
import 'package:rest4more/providers/repository_providers.dart';

import 'onboarding/notification_permission_flow.dart';
import 'progress/patterns_view.dart';
import 'progress/progress_widgets.dart';
import 'progress/this_week_view.dart';
import 'today_screen.dart' show RestPalette, RestType;

enum ProgressView { thisWeek, patterns }

/// Wat de app bijhoudt over je momenten: een weekoverzicht en patronen over
/// de laatste vier weken. Alleen de eigen sessies van de app, geen gebruik
/// van het toestel. Al het rekenwerk zit in `ProgressAnalytics`.
class ProgressTab extends ConsumerStatefulWidget {
  const ProgressTab({super.key, this.initialView = ProgressView.thisWeek});

  final ProgressView initialView;

  @override
  ConsumerState<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends ConsumerState<ProgressTab> {
  late ProgressView _view = widget.initialView;
  int _weeksBack = 0;
  ComparePeriod _period = ComparePeriod.lastWeek;

  /// Opent de tijdkiezer van de dagelijkse herinnering, al op [minutes].
  /// Staat de herinnering uit, dan eerst om toestemming vragen, net als op
  /// het profiel.
  Future<void> _moveReminder(int minutes, EarlyStopInsight? insight) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked == null || !mounted) return;
    final chosen = picked.hour * 60 + picked.minute;
    final time = picked.format(context);
    final profile = ref.read(profileProvider).value;
    if (profile?.notifyProgramme != true) {
      final outcome = await askReminderPermission(context, ref, time: time);
      if (outcome != ReminderPermissionOutcome.granted || !mounted) return;
    }
    try {
      await ref
          .read(profileRepositoryProvider)
          .setNotification(enabled: true, minutes: chosen);
      await ref.read(reminderServiceProvider).sync();
    } on Object {
      return;
    }
    if (insight != null) {
      await ref
          .read(progressSettingsProvider.notifier)
          .dismissInsight(insight.signature);
    }
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).progressReminderMoved(time)),
      ),
    );
  }

  Future<void> _changeEveningStart() async {
    final current = ref.read(progressSettingsProvider).eveningStartMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    await ref
        .read(progressSettingsProvider.notifier)
        .setEveningStart(picked.hour * 60 + picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(progressSummaryProvider);
    final analytics = ref.watch(progressAnalyticsProvider);
    final settings = ref.watch(progressSettingsProvider);

    Widget body;
    if (summary.hasError || analytics.hasError) {
      body = Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Text(l10n.progressLoadError, style: RestType.sans(15)),
      );
    } else if (!summary.hasValue || !analytics.hasValue) {
      body = const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      final a = analytics.value!;
      final s = summary.value!;
      body = switch (_view) {
        ProgressView.thisWeek => ThisWeekView(
          week: a.week(_weeksBack),
          comparison: a.compare(_weeksBack, _period),
          eveningStartMinutes: settings.eveningStartMinutes,
          onPreviousWeek: () => setState(() => _weeksBack++),
          onNextWeek: () => setState(
            () => _weeksBack = _weeksBack > 0 ? _weeksBack - 1 : 0,
          ),
          onPeriodChanged: (p) => setState(() => _period = p),
          onSeePatterns: () => setState(() => _view = ProgressView.patterns),
          stepsCard: _StepsCard(s),
          summary: s,
        ),
        ProgressView.patterns => () {
          final report = a.patterns();
          final profile = ref.watch(profileProvider).value;
          return PatternsView(
            report: report,
            eveningStartMinutes: settings.eveningStartMinutes,
            showInsight:
                report.insight?.signature != settings.dismissedInsight,
            reminderMinutes: profile?.notifyProgramme == true
                ? profile?.notifyTimeMinutes
                : null,
            onMoveReminder: (m) => _moveReminder(m, report.insight),
            onChangeEveningStart: _changeEveningStart,
            onDismissInsight: (i) => ref
                .read(progressSettingsProvider.notifier)
                .dismissInsight(i.signature),
          );
        }(),
      };
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Semantics(
            header: true,
            child: Text(l10n.tabProgress, style: RestType.serif(40)),
          ),
          const SizedBox(height: 20),
          ProgressSegmented<ProgressView>(
            options: ProgressView.values,
            selected: _view,
            onSelected: (v) => setState(() => _view = v),
            labelOf: (v) => switch (v) {
              ProgressView.thisWeek => l10n.progressTabThisWeek,
              ProgressView.patterns => l10n.progressTabPatterns,
            },
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  const _StepsCard(this.s);
  final ProgressSummary s;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final legend = [
      (l10n.progressStatusDone, Icons.check_circle),
      (l10n.progressStatusSkipped, Icons.remove_circle_outline),
      (l10n.progressStatusOpen, Icons.circle_outlined),
      (l10n.progressLegendSwapped, Icons.swap_horiz),
    ];
    return ProgressCard(
      title: l10n.progressDailySteps,
      children: [
        if (s.stepsTotal == 0)
          Text(l10n.progressNoPlan, style: RestType.sans(15))
        else ...[
          ProgressStat(
            l10n.progressCountOfTotal(s.stepsCompleted, s.stepsTotal),
            l10n.progressStepsDone,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final d in s.stepDays) _StepDot(d)],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              for (final e in legend)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(e.$2, size: 14, color: RestPalette.primary),
                    const SizedBox(width: 4),
                    Text(e.$1, style: RestType.sans(12)),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot(this.day);
  final StepDay day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (icon, label) = switch (day.status) {
      DayStatus.completed => (Icons.check_circle, l10n.progressStatusDone),
      DayStatus.skipped => (
        Icons.remove_circle_outline,
        l10n.progressStatusSkipped,
      ),
      _ => (Icons.circle_outlined, l10n.progressStatusOpen),
    };
    // Alleen een afgeronde stap is echt ingekort gedaan. Bij een open of
    // overgeslagen stap zegt de grootte niets, ook als het hele plan klein is.
    final swapped =
        day.size == DaySize.smaller && day.status == DayStatus.completed;
    return Semantics(
      label: swapped
          ? l10n.progressDayStatusSwapped(day.dayNumber, label)
          : l10n.progressDayStatus(day.dayNumber, label),
      excludeSemantics: true,
      child: SizedBox(
        width: 36,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 22, color: RestPalette.primary),
                if (swapped)
                  Positioned(
                    right: -6,
                    bottom: -4,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: RestPalette.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.swap_horiz,
                        size: 13,
                        color: RestPalette.accent,
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              '${day.dayNumber}',
              style: RestType.sans(11, color: RestPalette.accent),
            ),
          ],
        ),
      ),
    );
  }
}
