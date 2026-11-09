import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/progress/progress_summary.dart';
import 'package:rest4more/l10n/app_localizations.dart';
import 'package:rest4more/l10n/format.dart';
import 'package:rest4more/providers/repository_providers.dart';

import 'today_screen.dart' show RestPalette, RestType;

/// Wat de app tot nu toe bijhoudt: beschermde momenten, stappen en wat de
/// gebruiker zelf heeft ingevuld. Ontbrekende waarden blijven leeg.
class ProgressTab extends ConsumerWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(progressSummaryProvider);
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Text(l10n.progressLoadError, style: RestType.sans(15)),
        ),
        data: (s) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            Text(l10n.tabProgress, style: RestType.serif(34)),
            const SizedBox(height: 20),
            _MomentsCard(s),
            const SizedBox(height: 14),
            _StepsCard(s),
            const SizedBox(height: 14),
            _PhoneAwayCard(s),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: RestPalette.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: RestPalette.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: RestType.sans(13, color: RestPalette.accent)),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value, style: RestType.serif(30)),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: RestType.sans(14))),
      ],
    ),
  );
}

class _MomentsCard extends StatelessWidget {
  const _MomentsCard(this.s);
  final ProgressSummary s;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (s.completedMoments == 0) {
      return _Card(
        title: l10n.progressMoments,
        children: [Text(l10n.progressNoMoments, style: RestType.sans(14))],
      );
    }
    final minutes = (s.protectedSeconds / 60).round();
    return _Card(
      title: l10n.progressMoments,
      children: [
        _Stat('${s.completedMoments}', l10n.progressMomentsCompleted),
        _Stat('${s.completedMomentsLast7Days}', l10n.progressLast7Days),
        _Stat(localizedDuration(l10n, minutes), l10n.progressInTotal),
        _Stat(
          '${s.daysWithMoment}',
          l10n.progressDaysWithMoment(s.daysWithMoment),
        ),
        const SizedBox(height: 4),
        _WeekStrip(s.last7Days),
        if (s.plannedMoments > 0) ...[
          const SizedBox(height: 16),
          Text(
            l10n.progressPlannedVsActual,
            style: RestType.sans(13, color: RestPalette.accent),
          ),
          const SizedBox(height: 8),
          _Stat(
            l10n.progressActualOfPlannedValue(
              (s.plannedActualSeconds / 60).round(),
              (s.plannedSeconds / 60).round(),
            ),
            l10n.progressActualOfPlanned,
          ),
          _Stat(
            l10n.progressCountOfTotal(s.plannedFullLength, s.plannedMoments),
            l10n.progressFullLength,
          ),
        ],
      ],
    );
  }
}

/// De laatste 7 dagen, gevuld als er die dag een moment is afgerond.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip(this.days);
  final List<MomentDay> days;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final d in days)
          Semantics(
            excludeSemantics: true,
            label: d.moments == 0
                ? l10n.progressDayNoMoment(d.date)
                : l10n.progressDayMoments(d.date, d.moments),
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: d.moments > 0
                        ? RestPalette.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: d.moments > 0
                          ? RestPalette.primary
                          : RestPalette.border,
                      width: 1.5,
                    ),
                  ),
                  child: d.moments > 0
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  localizedWeekday(context, d.weekday).substring(0, 1),
                  style: RestType.sans(11, color: RestPalette.accent),
                ),
              ],
            ),
          ),
      ],
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
    return _Card(
      title: l10n.progressDailySteps,
      children: [
        if (s.stepsTotal == 0)
          Text(l10n.progressNoPlan, style: RestType.sans(14))
        else ...[
          _Stat(
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

class _PhoneAwayCard extends StatelessWidget {
  const _PhoneAwayCard(this.s);
  final ProgressSummary s;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String format(int seconds) =>
        localizedDuration(l10n, (seconds / 60).round());
    return _Card(
      title: l10n.progressPhoneAway,
      children: [
        if (s.blockedSeconds == 0)
          Text(l10n.progressNoBlocked, style: RestType.sans(14))
        else ...[
          _Stat(format(s.blockedSeconds), l10n.progressBlockedTotal),
          _Stat(format(s.blockedSecondsLast7Days), l10n.progressLast7Days),
        ],
      ],
    );
  }
}
