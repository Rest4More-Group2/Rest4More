import 'package:flutter/material.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/progress/progress_analytics.dart';
import 'package:rest4more/l10n/app_localizations.dart';
import 'package:rest4more/l10n/format.dart';

import '../today_screen.dart' show RestPalette, RestType;
import 'progress_widgets.dart';

/// Patronen over de laatste vier weken: wanneer en waarom momenten eerder
/// stoppen. Bij te weinig momenten alleen de uitleg en de voortgang daarheen.
/// Rekent zelf niets uit; alles komt uit [PatternsReport].
class PatternsView extends StatelessWidget {
  const PatternsView({
    super.key,
    required this.report,
    required this.eveningStartMinutes,
    required this.showInsight,
    required this.reminderMinutes,
    required this.onMoveReminder,
    required this.onChangeEveningStart,
    required this.onDismissInsight,
  });

  final PatternsReport report;
  final int eveningStartMinutes;

  /// False als de gebruiker dit inzicht heeft weggeklikt.
  final bool showInsight;

  /// De huidige dagelijkse herinnering, of null als die uit staat.
  final int? reminderMinutes;
  final ValueChanged<int> onMoveReminder;
  final VoidCallback onChangeEveningStart;
  final ValueChanged<EarlyStopInsight> onDismissInsight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!report.enoughData) return _LowDataCard(moments: report.moments);
    final insight = report.insight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.progressPatternsBasis(report.moments, report.endedEarly),
          style: RestType.sans(13, color: RestPalette.accent),
        ),
        const SizedBox(height: 14),
        if (insight != null && showInsight) ...[
          _InsightCard(
            insight: insight,
            eveningStartMinutes: eveningStartMinutes,
            reminderMinutes: reminderMinutes,
            onMoveReminder: onMoveReminder,
            onChangeEveningStart: onChangeEveningStart,
            onDismiss: () => onDismissInsight(insight),
          ),
          const SizedBox(height: 14),
        ],
        _WhenCard(
          report: report,
          eveningStartMinutes: eveningStartMinutes,
          onChange: onChangeEveningStart,
        ),
        if (report.endedEarly > 0) ...[
          const SizedBox(height: 14),
          _WhyCard(report: report),
        ],
        const SizedBox(height: 14),
        _WeekdayCard(report: report),
      ],
    );
  }
}

class _LowDataCard extends StatelessWidget {
  const _LowDataCard({required this.moments});
  final int moments;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filled = moments.clamp(0, minSample);
    return ProgressCard(
      title: l10n.progressTabPatterns,
      children: [
        Text(l10n.progressLowDataTitle(minSample), style: RestType.serif(30)),
        const SizedBox(height: 14),
        Text(l10n.progressLowDataBody, style: RestType.sans(15)),
        const SizedBox(height: 18),
        ExcludeSemantics(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < minSample; i++)
                Container(
                  key: ValueKey('low-data-dot-$i'),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < filled ? RestPalette.primary : Colors.transparent,
                    border: Border.all(
                      color: i < filled
                          ? RestPalette.primary
                          : progressMutedBar,
                      width: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.progressLowDataCount(filled, minSample),
          style: RestType.sans(15, color: RestPalette.accent),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.insight,
    required this.eveningStartMinutes,
    required this.reminderMinutes,
    required this.onMoveReminder,
    required this.onChangeEveningStart,
    required this.onDismiss,
  });

  final EarlyStopInsight insight;
  final int eveningStartMinutes;
  final int? reminderMinutes;
  final ValueChanged<int> onMoveReminder;
  final VoidCallback onChangeEveningStart;
  final VoidCallback onDismiss;

  /// Minuten na de avondstart, zodat 00:30 later is dan 22:00.
  int _offset(int minutes) => (minutes - eveningStartMinutes) % (24 * 60);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final when = bucketPhrase(context, insight.bucket, eveningStartMinutes);
    final headline = insight.count == insight.of
        ? l10n.progressSentenceAllEarly(insight.count, when)
        : l10n.progressEarlyOfTotal(insight.count, insight.of, when);
    final body = switch (insight.bucket) {
      EveningBucket.later => l10n.progressInsightLaterBody,
      EveningBucket.firstPart => l10n.progressInsightFirstBody,
      EveningBucket.before => l10n.progressInsightBeforeBody(
        formatMinutesOfDay(context, eveningStartMinutes),
      ),
    };

    // Alleen voorstellen als de herinnering nu later (of uit) staat.
    final suggested = insight.suggestedReminderMinutes;
    final current = reminderMinutes;
    final canMove =
        suggested != null &&
        (current == null || _offset(current) > _offset(suggested));
    final (String, VoidCallback)? action = canMove
        ? (
            l10n.progressInsightMoveReminder(
              formatMinutesOfDay(context, suggested),
            ),
            () => onMoveReminder(suggested),
          )
        : insight.bucket == EveningBucket.before
        ? (l10n.progressInsightChangeEvening, onChangeEveningStart)
        : null;

    return ProgressCard(
      title: l10n.progressInsightTitle,
      highlighted: true,
      children: [
        Text(headline, style: RestType.serif(28)),
        const SizedBox(height: 12),
        Text(body, style: RestType.sans(15)),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (action != null)
              FilledButton(
                onPressed: action.$2,
                style: FilledButton.styleFrom(
                  backgroundColor: RestPalette.primary,
                  foregroundColor: RestPalette.background,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: Text(
                  action.$1,
                  textAlign: TextAlign.center,
                  style: RestType.sans(
                    15,
                    color: RestPalette.background,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            TextButton(
              onPressed: onDismiss,
              style: TextButton.styleFrom(
                foregroundColor: RestPalette.ink,
                minimumSize: const Size(0, 48),
              ),
              child: Text(l10n.progressInsightNotNow, style: RestType.sans(15)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Het grootste aantal, alleen als dat er maar één keer in staat.
T? _uniqueMax<T>(Map<T, int> counts) {
  T? best;
  var max = 0;
  var tie = false;
  for (final MapEntry(:key, :value) in counts.entries) {
    if (value > max) {
      best = key;
      max = value;
      tie = false;
    } else if (value == max && value > 0) {
      tie = true;
    }
  }
  return tie ? null : best;
}

class _WhenCard extends StatelessWidget {
  const _WhenCard({
    required this.report,
    required this.eveningStartMinutes,
    required this.onChange,
  });

  final PatternsReport report;
  final int eveningStartMinutes;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final counts = report.earlyByBucket;
    final max = counts.values.fold<int>(0, (m, n) => n > m ? n : m);
    final top = _uniqueMax(counts);
    return ProgressCard(
      title: l10n.progressWhenTitle,
      children: [
        if (report.endedEarly == 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(l10n.progressNoEarlyStops, style: RestType.sans(15)),
          )
        else
          for (final bucket in EveningBucket.values)
            ProgressCountBar(
              label: bucketLabel(context, bucket, eveningStartMinutes),
              count: counts[bucket] ?? 0,
              max: max,
              emphasized: bucket == top,
            ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  l10n.progressWhenFooter(
                    formatMinutesOfDay(context, eveningStartMinutes),
                  ),
                  style: RestType.sans(13, color: RestPalette.accent),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: l10n.progressChangeEveningTooltip,
              child: TextButton(
                onPressed: onChange,
                style: TextButton.styleFrom(
                  foregroundColor: RestPalette.accent,
                  minimumSize: const Size(48, 44),
                ),
                child: Text(
                  l10n.progressChange,
                  style: RestType.sans(
                    13,
                    color: RestPalette.accent,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WhyCard extends StatelessWidget {
  const _WhyCard({required this.report});
  final PatternsReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String label(EndReason r) => switch (r) {
      EndReason.couldntSleep => l10n.endReasonCouldntSleep,
      EndReason.neededPhone => l10n.endReasonNeededPhone,
      EndReason.notification => l10n.endReasonNotification,
      EndReason.justWanted => l10n.endReasonJustWanted,
      EndReason.other || EndReason.unknown => l10n.endReasonOther,
    };
    final reasons = report.reasons;
    final max = reasons.values.fold<int>(0, (m, n) => n > m ? n : m);
    final top = _uniqueMax(reasons);
    return ProgressCard(
      title: l10n.progressWhyTitle,
      children: [
        if (reasons.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(l10n.progressWhyNone, style: RestType.sans(15)),
          )
        else
          for (final MapEntry(key: reason, value: count) in reasons.entries)
            ProgressCountBar(
              label: label(reason),
              count: count,
              max: max,
              emphasized: reason == top,
            ),
        Text(
          l10n.progressWhyFooter(report.withReason, report.endedEarly),
          style: RestType.sans(13, color: RestPalette.accent),
        ),
      ],
    );
  }
}

class _WeekdayCard extends StatelessWidget {
  const _WeekdayCard({required this.report});
  final PatternsReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final weekend = report.weekend;
    return ProgressCard(
      title: l10n.progressWeekdayTitle,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final d in report.weekdays)
              Expanded(child: _WeekdayRing(d)),
          ],
        ),
        if (weekend != null) ...[
          const SizedBox(height: 14),
          Text(
            weekend.harder
                ? l10n.progressWeekendHarder(weekend.completed, weekend.total)
                : l10n.progressWeekendEasier(weekend.completed, weekend.total),
            style: RestType.sans(15),
          ),
        ],
      ],
    );
  }
}

class _WeekdayRing extends StatelessWidget {
  const _WeekdayRing(this.day);
  final WeekdayTally day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final full = day.total > 0 && day.completed == day.total;
    return Semantics(
      label: l10n.progressWeekdayRing(
        localizedWeekday(context, day.weekday),
        day.completed,
        day.total,
      ),
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: full
                ? const DecoratedBox(
                    decoration: BoxDecoration(
                      color: RestPalette.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                : CircularProgressIndicator(
                    value: day.total == 0 ? 0 : day.completed / day.total,
                    strokeWidth: 5,
                    color: RestPalette.primary,
                    backgroundColor: progressMutedBar,
                    strokeCap: StrokeCap.round,
                  ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${day.completed}/${day.total}',
              style: RestType.sans(12),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              weekdayInitial(context, day.weekday),
              style: RestType.sans(12, color: RestPalette.accent),
            ),
          ),
        ],
      ),
    );
  }
}
