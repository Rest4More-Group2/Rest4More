import 'package:rest4more/l10n/format.dart';
import 'package:rest4more/l10n/app_localizations.dart';
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
    this.onStartNow,
    this.now,
  });

  final MorningPlan? initial;
  final ValueChanged<MorningPlan>? onSave;
  final Future<void> Function(MorningPlan)? onStartNow;

  /// Voor tests: de "nu" waarmee het voorbeeld wordt uitgerekend.
  final DateTime? now;

  @override
  State<MorningScreen> createState() => _MorningScreenState();
}

class _MorningScreenState extends State<MorningScreen> {
  late MorningPlan _plan = widget.initial ?? MorningPlan.initial();

  void _setDay(MorningDay day) => setState(() {
    _plan = _plan.copyWith(
      days: [for (final d in _plan.days) d.weekday == day.weekday ? day : d],
    );
  });

  void _setAllTimes(int minutes) => setState(() {
    _plan = _plan.copyWith(
      days: [for (final day in _plan.days) day.copyWith(wakeMinutes: minutes)],
    );
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
      title: AppLocalizations.of(context).momentMorningTitle,
      subtitle: AppLocalizations.of(context).momentMorningDescription,
      bottom: MomentPrimaryButton(
        label: AppLocalizations.of(context).saveMorning,
        onPressed: widget.onSave == null || steps.isEmpty
            ? null
            : () => widget.onSave!(_plan),
      ),
      children: [
        const MomentAppsSection(kind: MomentKind.morning),
        MomentSection(
          title: AppLocalizations.of(context).wakeUpTimePerDay,
          note: AppLocalizations.of(context).wakeUpNote,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(AppLocalizations.of(context).setTimeForAllDays),
                  ),
                  TimeButton(
                    minutes: _plan.days.first.wakeMinutes,
                    onChanged: _setAllTimes,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final day in _plan.days)
                WeekdayTimeRow(
                  name: localizedWeekday(context, day.weekday),
                  enabled: day.enabled,
                  minutes: day.wakeMinutes,
                  onEnabled: (v) => _setDay(day.copyWith(enabled: v)),
                  onMinutes: (m) => _setDay(day.copyWith(wakeMinutes: m)),
                ),
            ],
          ),
        ),
        MomentSection(
          title: AppLocalizations.of(context).yourMorning,
          note: AppLocalizations.of(context).yourMorningNote,
          child: RoutineStepsEditor(
            steps: steps,
            library: morningStepLibrary,
            onChanged: (s) => setState(() => _plan = _plan.copyWith(steps: s)),
          ),
        ),
        if (preview != null && steps.isNotEmpty)
          MomentSection(
            title: AppLocalizations.of(context).yourWeekdayMorning(
              localizedWeekday(context, preview.day.weekday),
            ),
            note: AppLocalizations.of(context).timerOnlyNote,
            child: _timeline(preview.start, preview.end),
          ),
        Text(
          AppLocalizations.of(context).timesFollowClock,
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
                ? AppLocalizations.of(context).blockingStartsHere
                : localizedDuration(
                    AppLocalizations.of(context),
                    stepMinutes(_plan.steps[i]),
                  ),
          ),
        TimelineRow(
          time: formatTime(end),
          title: AppLocalizations.of(context).phoneIsBack,
          detail: AppLocalizations.of(context).appsUnlock,
          last: true,
        ),
      ],
    );
  }
}
