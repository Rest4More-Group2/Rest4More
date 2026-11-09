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

/// Avondpagina: je kiest wanneer je naar bed gaat en wat je avond bevat, de
/// app telt terug.
class EveningScreen extends StatefulWidget {
  const EveningScreen({
    super.key,
    this.initial,
    this.onSave,
    this.onStartNow,
    this.now,
  });

  final EveningPlan? initial;
  final ValueChanged<EveningPlan>? onSave;
  final Future<void> Function(EveningPlan)? onStartNow;

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

  void _setAllTimes(int minutes) => setState(() {
        _plan = _plan.copyWith(days: [
          for (final day in _plan.days) day.copyWith(bedtimeMinutes: minutes),
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
      title: AppLocalizations.of(context).momentEveningTitle,
      subtitle: AppLocalizations.of(context).eveningSubtitle,
      bottom: MomentPrimaryButton(
        label: AppLocalizations.of(context).saveEvening,
        onPressed: widget.onSave == null || steps.isEmpty
            ? null
            : () => widget.onSave!(_plan),
      ),
      children: [
        const MomentAppsSection(kind: MomentKind.evening),
        MomentSection(
          title: AppLocalizations.of(context).bedtimePerDay,
          note: AppLocalizations.of(context).bedtimeNote,
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Set time for all days')),
                  TimeButton(
                    minutes: _plan.days.first.bedtimeMinutes,
                    onChanged: _setAllTimes,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final day in _plan.days)
                WeekdayTimeRow(
                  name: localizedWeekday(context, day.weekday),
                  enabled: day.enabled,
                  minutes: day.bedtimeMinutes,
                  hint: day.bedtimeAfterMidnight ? AppLocalizations.of(context).eveningAfterMidnight : null,
                  onEnabled: (v) => _setDay(day.copyWith(enabled: v)),
                  onMinutes: (m) => _setDay(day.copyWith(bedtimeMinutes: m)),
                ),
            ],
          ),
        ),
        MomentSection(
          title: AppLocalizations.of(context).yourEvening,
          note: AppLocalizations.of(context).yourEveningNote,
          child: RoutineStepsEditor(
            steps: steps,
            library: eveningStepLibrary,
            onChanged: (s) => setState(() => _plan = _plan.copyWith(steps: s)),
          ),
        ),
        MomentSection(
          title: AppLocalizations.of(context).reminders,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(AppLocalizations.of(context).headsUpBefore),
              ChoiceChips<int>(
                options: const [15, 30, 45, 60],
                selected: _plan.windDownLeadMinutes,
                onSelected: (v) => setState(
                    () => _plan = _plan.copyWith(windDownLeadMinutes: v)),
                labelOf: (v) => AppLocalizations.of(context).minutesShort(v),
              ),
              const SizedBox(height: 16),
              _label(AppLocalizations.of(context).secondReminder),
              ChoiceChips<int>(
                options: const [0, 5, 10, 15, 30],
                selected: _plan.secondReminderMinutes,
                onSelected: (v) => setState(
                    () => _plan = _plan.copyWith(secondReminderMinutes: v)),
                labelOf: (v) => v == 0 ? AppLocalizations.of(context).off : AppLocalizations.of(context).afterMinutes(v),
              ),
            ],
          ),
          note: AppLocalizations.of(context).remindersNote,
        ),
        MomentSection(
          title: AppLocalizations.of(context).whenBlockingEnds,
          child: ChoiceChips<EveningEnd>(
            options: EveningEnd.values,
            selected: _plan.end,
            onSelected: (v) => setState(() => _plan = _plan.copyWith(end: v)),
            labelOf: (v) => eveningEndLabel(AppLocalizations.of(context), v),
          ),
          note: strict
              ? AppLocalizations.of(context).strictOvernight
              : AppLocalizations.of(context).liftsAtBedtime,
        ),
        if (preview != null && steps.isNotEmpty)
          MomentSection(
            title: AppLocalizations.of(context).yourWeekdayEvening(localizedWeekday(context, preview.day.weekday)),
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
          title: AppLocalizations.of(context).headsUp,
          detail: AppLocalizations.of(context).headsUpDetail,
        ),
        for (var i = 0; i < _plan.steps.length; i++)
          TimelineRow(
            time: formatTime(clock[i]),
            title: _plan.steps[i].title,
            detail: i == 0
                ? AppLocalizations.of(context).blockingStartsHere
                : localizedDuration(AppLocalizations.of(context), stepMinutes(_plan.steps[i])),
          ),
        TimelineRow(
          time: formatTime(times.bedtime),
          title: strict ? AppLocalizations.of(context).bedtime : AppLocalizations.of(context).bedtimeBlockingEnds,
          detail: strict ? AppLocalizations.of(context).blockingStaysUntilScan : null,
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
