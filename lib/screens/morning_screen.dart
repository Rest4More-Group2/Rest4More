import 'package:flutter/material.dart';
import 'package:rest4more/data/moments/moment_plans.dart';
import 'package:rest4more/data/moments/moment_profiles.dart';
import 'package:rest4more/data/moments/moment_schedule.dart';

import 'moment_apps_section.dart';
import 'moments_form_widgets.dart';
import 'routine_steps_editor.dart';
import 'today_screen.dart' show RestType;

/// Ochtendpagina: je geeft je opstaantijd in en wat je ochtend bevat. De
/// telefoon komt pas na die stappen. De systeemwekker is niet te koppelen,
/// daarom is de tijd hier een eigen instelling.
class MorningScreen extends StatefulWidget {
  const MorningScreen({
    super.key,
    this.initial,
    this.onSave,
    this.now,
  });

  final MorningPlan? initial;
  final ValueChanged<MorningPlan>? onSave;

  /// Voor tests: de "nu" waarmee het voorbeeld wordt uitgerekend.
  final DateTime? now;

  @override
  State<MorningScreen> createState() => _MorningScreenState();
}

class _MorningScreenState extends State<MorningScreen> {
  late MorningPlan _plan = widget.initial ?? MorningPlan.initial();

  void _setDay(MorningDay day) => setState(() {
        _plan = _plan.copyWith(days: [
          for (final d in _plan.days) d.weekday == day.weekday ? day : d,
        ]);
      });

  ({MorningDay day, DateTime start, DateTime end})? _preview() {
    final now = widget.now ?? DateTime.now();
    for (var i = 0; i < 7; i++) {
      final date = DateTime(now.year, now.month, now.day + i);
      final day = _plan.days.firstWhere((d) => d.weekday == date.weekday);
      if (!day.enabled) continue;
      final window = morningWindow(
        morningDate: date,
        wakeMinutes: day.wakeMinutes,
        blockMinutes: totalMinutes(_plan.steps),
      );
      return (day: day, start: window.start, end: window.end);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview();
    final steps = _plan.steps;
    return MomentPage(
      title: 'Morning',
      subtitle: 'Start the day before your phone does.',
      bottom: MomentPrimaryButton(
        label: 'Save morning',
        onPressed: widget.onSave == null || steps.isEmpty
            ? null
            : () => widget.onSave!(_plan),
      ),
      children: [
        const MomentAppsSection(kind: MomentKind.morning),
        MomentSection(
          title: 'Wake-up time per day',
          note: 'This is not your phone alarm. The app cannot hook into the '
              'system alarm, so set the same time there. Your morning starts '
              'at the time you choose here.',
          child: Column(
            children: [
              for (final day in _plan.days)
                WeekdayTimeRow(
                  name: weekdayName(day.weekday),
                  enabled: day.enabled,
                  minutes: day.wakeMinutes,
                  onEnabled: (v) => _setDay(day.copyWith(enabled: v)),
                  onMinutes: (m) => _setDay(day.copyWith(wakeMinutes: m)),
                ),
            ],
          ),
        ),
        MomentSection(
          title: 'Your morning',
          note: 'Everything you do before your phone comes back. Your phone '
              'is not a step. It is what comes after.',
          child: RoutineStepsEditor(
            steps: steps,
            library: morningStepLibrary,
            onChanged: (s) => setState(() => _plan = _plan.copyWith(steps: s)),
          ),
        ),
        if (preview != null && steps.isNotEmpty)
          MomentSection(
            title: 'Your ${weekdayName(preview.day.weekday)} morning',
            note: 'Timer only: apps unlock by themselves when your steps are '
                'done. This is not a strict block.',
            child: _timeline(preview.start, preview.end),
          ),
        Text(
          'Times follow your phone’s clock and time zone.',
          style: RestType.sans(12),
        ),
      ],
    );
  }

  Widget _timeline(DateTime start, DateTime end) {
    final clock = stepClock(start, _plan.steps);
    return Column(
      children: [
        for (var i = 0; i < _plan.steps.length; i++)
          TimelineRow(
            time: formatTime(clock[i]),
            title: _plan.steps[i].title,
            detail: i == 0
                ? 'Blocking starts here.'
                : formatDuration(stepMinutes(_plan.steps[i])),
          ),
        TimelineRow(
          time: formatTime(end),
          title: 'Your phone is back',
          detail: 'Apps unlock.',
          last: true,
        ),
      ],
    );
  }
}
