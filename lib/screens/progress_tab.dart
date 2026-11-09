import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/progress/progress_summary.dart';
import 'package:rest4more/providers/repository_providers.dart';

import 'today_screen.dart' show RestPalette, RestType;

/// Wat de app tot nu toe bijhoudt: beschermde momenten, stappen en wat de
/// gebruiker zelf heeft ingevuld. Ontbrekende waarden blijven leeg.
class ProgressTab extends ConsumerWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(progressSummaryProvider);
    return SafeArea(
      child: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Text('Progress could not be loaded.', style: RestType.sans(15)),
        ),
        data: (s) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            Text('Progress', style: RestType.serif(34)),
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
    if (s.completedMoments == 0) {
      return _Card(
        title: 'Moments',
        children: [
          Text(
            'No completed moments yet. They appear here once you finish one.',
            style: RestType.sans(14),
          ),
        ],
      );
    }
    final minutes = (s.protectedSeconds / 60).round();
    return _Card(
      title: 'Moments',
      children: [
        _Stat('${s.completedMoments}', 'completed in total'),
        _Stat('${s.completedMomentsLast7Days}', 'in the last 7 days'),
        _Stat('$minutes min', 'in total'),
        _Stat('${s.daysWithMoment}', s.daysWithMoment == 1
            ? 'day with a moment'
            : 'days with a moment'),
        const SizedBox(height: 4),
        _WeekStrip(s.last7Days),
        if (s.plannedMoments > 0) ...[
          const SizedBox(height: 16),
          Text('Planned vs actual',
              style: RestType.sans(13, color: RestPalette.accent)),
          const SizedBox(height: 8),
          _Stat('${(s.plannedActualSeconds / 60).round()} of '
              '${(s.plannedSeconds / 60).round()} min',
              'actual of planned time'),
          _Stat('${s.plannedFullLength} of ${s.plannedMoments}',
              'lasted their full planned time'),
        ],
      ],
    );
  }
}

/// De laatste 7 dagen, gevuld als er die dag een moment is afgerond.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip(this.days);
  final List<MomentDay> days;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      for (final d in days)
        Semantics(
          excludeSemantics: true,
          label: '${d.date}: ${d.moments == 0 ? 'no moment' : '${d.moments} moments'}',
          child: Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: d.moments > 0 ? RestPalette.primary : Colors.transparent,
                  border: Border.all(
                    color: d.moments > 0 ? RestPalette.primary : RestPalette.border,
                    width: 1.5,
                  ),
                ),
                child: d.moments > 0
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(_letters[d.weekday - 1],
                  style: RestType.sans(11, color: RestPalette.accent)),
            ],
          ),
        ),
    ],
  );
}

class _StepsCard extends StatelessWidget {
  const _StepsCard(this.s);
  final ProgressSummary s;

  @override
  Widget build(BuildContext context) => _Card(
    title: 'Daily steps',
    children: [
      if (s.stepsTotal == 0)
        Text('No plan started yet.', style: RestType.sans(14))
      else ...[
        _Stat('${s.stepsCompleted} of ${s.stepsTotal}', 'steps done'),
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
            for (final e in _legend)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(e.$2, size: 14, color: RestPalette.primary),
                const SizedBox(width: 4),
                Text(e.$1, style: RestType.sans(12)),
              ]),
          ],
        ),
      ],
    ],
  );

  static const _legend = [
    ('done', Icons.check_circle),
    ('skipped', Icons.remove_circle_outline),
    ('open', Icons.circle_outlined),
    ('swapped for a shorter step', Icons.swap_horiz),
  ];
}

class _StepDot extends StatelessWidget {
  const _StepDot(this.day);
  final StepDay day;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (day.status) {
      DayStatus.completed => (Icons.check_circle, 'done'),
      DayStatus.skipped => (Icons.remove_circle_outline, 'skipped'),
      _ => (Icons.circle_outlined, 'open'),
    };
    // Alleen een afgeronde stap is echt ingekort gedaan. Bij een open of
    // overgeslagen stap zegt de grootte niets, ook als het hele plan klein is.
    final swapped =
        day.size == DaySize.smaller && day.status == DayStatus.completed;
    return Semantics(
      label: 'Day ${day.dayNumber}: $label${swapped ? ', swapped' : ''}',
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
            Text('${day.dayNumber}',
                style: RestType.sans(11, color: RestPalette.accent)),
          ],
        ),
      ),
    );
  }
}

class _PhoneAwayCard extends StatelessWidget {
  const _PhoneAwayCard(this.s);
  final ProgressSummary s;

  static String _format(int seconds) {
    final minutes = (seconds / 60).round();
    return minutes < 60
        ? '$minutes min'
        : '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')} min';
  }

  @override
  Widget build(BuildContext context) => _Card(
    title: 'Phone-away',
    children: [
      if (s.blockedSeconds == 0)
        Text('No blocked time yet.', style: RestType.sans(14))
      else ...[
        _Stat(_format(s.blockedSeconds), 'apps blocked in total'),
        _Stat(_format(s.blockedSecondsLast7Days), 'in the last 7 days'),
      ],
    ],
  );
}
