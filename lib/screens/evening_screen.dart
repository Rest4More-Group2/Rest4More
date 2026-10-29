import 'package:flutter/material.dart';
import 'package:rest4more/data/moments/moment_plans.dart';
import 'package:rest4more/data/moments/moment_profiles.dart';
import 'package:rest4more/data/moments/moment_schedule.dart';

import 'moment_apps_section.dart';
import 'moments_form_widgets.dart';
import 'routine_steps_editor.dart';
import 'today_screen.dart' show RestType;

/// Avondpagina: je kiest wanneer je naar bed gaat en wat je avond bevat, de
/// app telt terug.
class EveningScreen extends StatefulWidget {
  const EveningScreen({
    super.key,
    this.initial,
    this.onSave,
    this.now,
  });

  final EveningPlan? initial;
  final ValueChanged<EveningPlan>? onSave;

  /// Voor tests: de "nu" waarmee het voorbeeld wordt uitgerekend.
  final DateTime? now;

  @override
  State<EveningScreen> createState() => _EveningScreenState();
}

class _EveningScreenState extends State<EveningScreen> {
  late EveningPlan _plan = widget.initial ?? EveningPlan.initial();

  void _setDay(EveningDay day) => setState(() {
        _plan = _plan.copyWith(days: [
          for (final d in _plan.days) d.weekday == day.weekday ? day : d,
        ]);
      });

  /// De eerstvolgende ingeschakelde avond, voor het voorbeeld.
  ({EveningDay day, EveningTimes times})? _preview() {
    final now = widget.now ?? DateTime.now();
    final total = totalMinutes(_plan.steps);
    for (var i = 0; i < 7; i++) {
      final date = DateTime(now.year, now.month, now.day + i);
      final day = _plan.days.firstWhere((d) => d.weekday == date.weekday);
      if (!day.enabled) continue;
      return (
        day: day,
        times: eveningTimes(
          eveningDate: date,
          bedtimeMinutes: day.bedtimeMinutes,
          windDownLeadMinutes: _plan.windDownLeadMinutes,
          blockLeadMinutes: total,
          graceMinutes: _plan.secondReminderMinutes,
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview();
    final strict = _plan.end == EveningEnd.atNextScan;
    final steps = _plan.steps;
    return MomentPage(
      title: 'Evening',
      subtitle: 'Pick your bedtime. We count back from there.',
      bottom: MomentPrimaryButton(
        label: 'Save evening',
        onPressed: widget.onSave == null || steps.isEmpty
            ? null
            : () => widget.onSave!(_plan),
      ),
      children: [
        const MomentAppsSection(kind: MomentKind.evening),
        MomentSection(
          title: 'Bedtime per day',
          note: 'A bedtime between 00:00 and 05:59 belongs to the evening '
              'before, so a Friday evening can end on Saturday at 00:30.',
          child: Column(
            children: [
              for (final day in _plan.days)
                WeekdayTimeRow(
                  name: weekdayName(day.weekday),
                  enabled: day.enabled,
                  minutes: day.bedtimeMinutes,
                  hint: day.bedtimeAfterMidnight ? 'After midnight' : null,
                  onEnabled: (v) => _setDay(day.copyWith(enabled: v)),
                  onMinutes: (m) => _setDay(day.copyWith(bedtimeMinutes: m)),
                ),
            ],
          ),
        ),
        MomentSection(
          title: 'Your evening',
          note: 'Your evening starts early enough to fit every step before '
              'bedtime. Putting your phone away comes first.',
          child: RoutineStepsEditor(
            steps: steps,
            library: eveningStepLibrary,
            onChanged: (s) => setState(() => _plan = _plan.copyWith(steps: s)),
          ),
        ),
        MomentSection(
          title: 'Reminders',
          note: 'Reminders are local notifications. The app can ask, but it '
              'cannot make you put your phone away, and your phone’s silent '
              'or Focus modes can still mute them.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Heads-up before your evening starts'),
              ChoiceChips<int>(
                options: const [15, 30, 45, 60],
                selected: _plan.windDownLeadMinutes,
                onSelected: (v) => setState(
                    () => _plan = _plan.copyWith(windDownLeadMinutes: v)),
                labelOf: (v) => '$v min',
              ),
              const SizedBox(height: 16),
              _label('Second reminder if you have not started'),
              ChoiceChips<int>(
                options: const [0, 5, 10, 15, 30],
                selected: _plan.secondReminderMinutes,
                onSelected: (v) => setState(
                    () => _plan = _plan.copyWith(secondReminderMinutes: v)),
                labelOf: (v) => v == 0 ? 'Off' : 'After $v min',
              ),
            ],
          ),
        ),
        MomentSection(
          title: 'When blocking ends',
          note: strict
              ? 'Strict overnight: blocking stays on until you scan. A timer '
                  'will not end it for you.'
              : 'Blocking lifts by itself at bedtime.',
          child: ChoiceChips<EveningEnd>(
            options: EveningEnd.values,
            selected: _plan.end,
            onSelected: (v) => setState(() => _plan = _plan.copyWith(end: v)),
            labelOf: (v) => v.label,
          ),
        ),
        if (preview != null && steps.isNotEmpty)
          MomentSection(
            title: 'Your ${weekdayName(preview.day.weekday)} evening',
            child: _timeline(preview.times, strict),
          ),
      ],
    );
  }

  Widget _timeline(EveningTimes times, bool strict) {
    final clock = stepClock(times.blockStart, _plan.steps);
    return Column(
      children: [
        TimelineRow(
          time: formatTime(times.windDown),
          title: 'Heads-up',
          detail: 'A reminder that your evening is about to start.',
        ),
        for (var i = 0; i < _plan.steps.length; i++)
          TimelineRow(
            time: formatTime(clock[i]),
            title: _plan.steps[i].title,
            detail: i == 0
                ? 'Blocking starts here.'
                : formatDuration(stepMinutes(_plan.steps[i])),
          ),
        TimelineRow(
          time: formatTime(times.bedtime),
          title: strict ? 'Bedtime' : 'Bedtime · blocking ends',
          detail: strict ? 'Blocking stays until your next scan.' : null,
          last: true,
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: RestType.sans(14, weight: FontWeight.w600)),
      );
}
