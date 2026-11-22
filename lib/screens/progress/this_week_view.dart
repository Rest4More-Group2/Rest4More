import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rest4more/data/progress/progress_analytics.dart';
import 'package:rest4more/data/progress/progress_summary.dart';
import 'package:rest4more/l10n/app_localizations.dart';
import 'package:rest4more/l10n/format.dart';

import '../today_screen.dart' show RestPalette, RestType;
import 'progress_widgets.dart';

/// De weekweergave: navigatie, "Your week", de vergelijking en de bestaande
/// kaarten voor stappen en telefoon-weg. Rekent zelf niets uit.
class ThisWeekView extends StatelessWidget {
  const ThisWeekView({
    super.key,
    required this.week,
    required this.comparison,
    required this.eveningStartMinutes,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onPeriodChanged,
    required this.onSeePatterns,
    required this.stepsCard,
    required this.summary,
  });

  final WeekReport week;
  final Comparison comparison;
  final int eveningStartMinutes;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final ValueChanged<ComparePeriod> onPeriodChanged;
  final VoidCallback onSeePatterns;
  final Widget stepsCard;
  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _WeekNavigator(
        week: week,
        onPrevious: onPreviousWeek,
        onNext: onNextWeek,
      ),
      const SizedBox(height: 12),
      _YourWeekCard(
        week: week,
        eveningStartMinutes: eveningStartMinutes,
        onSeePatterns: onSeePatterns,
      ),
      if (week.hasAnyMoments) ...[
        const SizedBox(height: 14),
        _CompareCard(
          comparison: comparison,
          isCurrentWeek: week.isCurrentWeek,
          onPeriodChanged: onPeriodChanged,
        ),
      ],
      const SizedBox(height: 14),
      stepsCard,
      const SizedBox(height: 14),
      _PhoneAwayCard(week: week, summary: summary),
    ],
  );
}

class _WeekNavigator extends StatelessWidget {
  const _WeekNavigator({
    required this.week,
    required this.onPrevious,
    required this.onNext,
  });

  final WeekReport week;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  String _range(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final start = week.start;
    final end = week.end;
    if (start.month == end.month && start.year == end.year) {
      return '${DateFormat.d(locale).format(start)} – '
          '${DateFormat.MMMMd(locale).format(end)}';
    }
    return '${DateFormat.MMMd(locale).format(start)} – '
        '${DateFormat.MMMd(locale).format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        IconButton(
          tooltip: l10n.progressPreviousWeek,
          onPressed: week.canGoBack ? onPrevious : null,
          icon: const Icon(Icons.chevron_left),
          color: RestPalette.primary,
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              _range(context),
              textAlign: TextAlign.center,
              style: RestType.sans(16, weight: FontWeight.w600),
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.progressNextWeek,
          onPressed: week.isCurrentWeek ? null : onNext,
          icon: const Icon(Icons.chevron_right),
          color: RestPalette.primary,
        ),
      ],
    );
  }
}

class _YourWeekCard extends StatelessWidget {
  const _YourWeekCard({
    required this.week,
    required this.eveningStartMinutes,
    required this.onSeePatterns,
  });

  final WeekReport week;
  final int eveningStartMinutes;
  final VoidCallback onSeePatterns;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = week.stats;
    if (!week.hasAnyMoments) {
      return ProgressCard(
        title: l10n.progressYourWeek,
        children: [Text(l10n.progressFirstWeekEmpty, style: RestType.sans(15))],
      );
    }
    final win = week.win;
    final sentence = week.sentence;
    return ProgressCard(
      title: l10n.progressYourWeek,
      children: [
        if (win != null) ...[
          _WinLine(_winText(l10n, win)),
          const SizedBox(height: 16),
        ],
        if (s.moments == 0)
          Text(l10n.progressWeekEmpty, style: RestType.sans(15))
        else ...[
          ProgressStat(
            l10n.progressCountOfTotal(s.completed, s.moments),
            l10n.progressMomentsCompletedLabel,
          ),
          if (s.protectedMinutes > 0)
            ProgressStat(
              localizedDuration(l10n, s.protectedMinutes),
              l10n.progressProtectedTime,
            ),
          if (s.unprotectedMinutes > 0)
            ProgressStat(
              localizedDuration(l10n, s.unprotectedMinutes),
              s.protectedMinutes > 0
                  ? l10n.progressSessionTimeNoBlocking
                  : l10n.progressSessionTime,
            ),
          ProgressStat('${s.endedEarly}', l10n.progressEndedEarlyLabel),
          const SizedBox(height: 8),
          Text(
            l10n.progressMinutesPerDay,
            style: RestType.sans(13, color: RestPalette.accent),
          ),
          const SizedBox(height: 10),
          _WeekBars(week.days),
          const SizedBox(height: 10),
          const _Legend(),
          if (sentence != null) ...[
            const SizedBox(height: 14),
            Text(
              _sentenceText(context, sentence),
              style: RestType.sans(15),
            ),
          ],
        ],
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: onSeePatterns,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: RestPalette.accent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    l10n.progressSeePatterns,
                    style: RestType.sans(
                      15,
                      color: RestPalette.accent,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _winText(AppLocalizations l10n, WeekWin win) => switch (win) {
    MoreCompletedWin(:final completed, :final more) =>
      l10n.progressWinMoreCompleted(completed, more),
    MoreProtectedWin(:final minutes, :final moreMinutes) =>
      l10n.progressWinMoreProtected(
        localizedDuration(l10n, minutes),
        localizedDuration(l10n, moreMinutes),
      ),
    FewerEarlyWin(:final fewer) => l10n.progressWinFewerEarly(fewer),
    CompletedWin(:final completed) => l10n.progressWinCompleted(completed),
  };

  String _sentenceText(BuildContext context, WeekSentence sentence) {
    final l10n = AppLocalizations.of(context);
    return switch (sentence) {
      NoneEndedEarlySentence() => l10n.progressSentenceNoneEarly,
      EarlyInBucketSentence(:final bucket, :final count, :final of) =>
        count == of
            ? l10n.progressSentenceAllEarly(
                count,
                bucketPhrase(context, bucket, eveningStartMinutes),
              )
            : l10n.progressEarlyOfTotal(
                count,
                of,
                bucketPhrase(context, bucket, eveningStartMinutes),
              ),
    };
  }
}

class _WinLine extends StatelessWidget {
  const _WinLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: RestPalette.badge,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ExcludeSemantics(
          child: Icon(Icons.check_circle, color: RestPalette.accent, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: RestType.sans(15))),
      ],
    ),
  );
}

/// Staafgrafiek van minuten per dag: afgerond onderaan, eerder gestopt erop,
/// met de waarde boven elke staaf.
class _WeekBars extends StatelessWidget {
  const _WeekBars(this.days);
  final List<DayBar> days;

  static const _maxHeight = 110.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final max = days.fold<int>(0, (m, d) => d.totalMinutes > m ? d.totalMinutes : m);
    double height(int minutes) {
      if (minutes == 0 || max == 0) return 0;
      return (minutes / max * _maxHeight).clamp(4, _maxHeight);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final d in days)
          Expanded(
            child: Semantics(
              label: l10n.progressBarSemantics(
                localizedWeekday(context, d.weekday),
                d.completedMinutes,
                d.endedEarlyMinutes,
              ),
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (d.totalMinutes > 0)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${d.totalMinutes}',
                          style: RestType.sans(12),
                        ),
                      ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        children: [
                          Container(
                            height: height(d.endedEarlyMinutes),
                            color: progressMutedBar,
                          ),
                          Container(
                            height: height(d.completedMinutes),
                            color: RestPalette.primary,
                          ),
                        ],
                      ),
                    ),
                    if (d.totalMinutes == 0)
                      Container(height: 2, color: RestPalette.border),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        weekdayInitial(context, d.weekday),
                        style: RestType.sans(12, color: RestPalette.accent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget item(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: RestType.sans(13))),
      ],
    );
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        item(RestPalette.primary, l10n.progressLegendCompleted),
        item(progressMutedBar, l10n.progressLegendEndedEarly),
      ],
    );
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({
    required this.comparison,
    required this.isCurrentWeek,
    required this.onPeriodChanged,
  });

  final Comparison comparison;
  final bool isCurrentWeek;
  final ValueChanged<ComparePeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = comparison;
    final lastWeek = c.period == ComparePeriod.lastWeek;
    String values(String now, String before) => !lastWeek
        ? l10n.progressCompare4Weeks(now, before)
        : isCurrentWeek
        ? l10n.progressCompareThisWeek(now, before)
        : l10n.progressCompareThatWeek(now, before);
    String duration(int m) => localizedDuration(l10n, m);
    final time = c.hasProtectedTime ? c.protectedMinutes : c.sessionMinutes;

    return ProgressCard(
      title: lastWeek
          ? l10n.progressComparedLastWeek
          : l10n.progressComparedLast4Weeks,
      children: [
        _CompareRow(
          title: l10n.progressCompareMoments,
          values: values('${c.completed.current}', '${c.completed.previous}'),
          delta: deltaLabel(l10n, c.completed.change),
        ),
        _CompareRow(
          title: c.hasProtectedTime
              ? l10n.progressCompareProtected
              : l10n.progressCompareSession,
          values: values(duration(time.current), duration(time.previous)),
          delta: deltaLabel(l10n, time.change, minutes: true),
        ),
        _CompareRow(
          title: l10n.progressCompareEnded,
          values: values('${c.endedEarly.current}', '${c.endedEarly.previous}'),
          delta: deltaLabel(l10n, c.endedEarly.change),
        ),
        const SizedBox(height: 4),
        ProgressToggle<ComparePeriod>(
          options: ComparePeriod.values,
          selected: c.period,
          onSelected: onPeriodChanged,
          labelOf: (p) => switch (p) {
            ComparePeriod.lastWeek => l10n.progressToggleLastWeek,
            ComparePeriod.last4Weeks => l10n.progressToggleLast4Weeks,
          },
        ),
      ],
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.title,
    required this.values,
    required this.delta,
  });

  final String title;
  final String values;
  final String delta;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: RestType.sans(15, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(values, style: RestType.sans(13, color: RestPalette.accent)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ProgressPill(delta),
        ],
      ),
    ),
  );
}

class _PhoneAwayCard extends StatelessWidget {
  const _PhoneAwayCard({required this.week, required this.summary});
  final WeekReport week;
  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String format(int seconds) =>
        localizedDuration(l10n, (seconds / 60).round());
    return ProgressCard(
      title: l10n.progressPhoneAway,
      children: [
        if (summary.blockedSeconds == 0)
          Text(l10n.progressNoBlocked, style: RestType.sans(15))
        else ...[
          ProgressStat(
            localizedDuration(l10n, week.stats.blockedMinutes),
            week.isCurrentWeek
                ? l10n.progressBlockedThisWeek
                : l10n.progressBlockedThatWeek,
          ),
          ProgressStat(format(summary.blockedSeconds), l10n.progressBlockedTotal),
          const SizedBox(height: 4),
          Text(
            l10n.progressBlockedSource,
            style: RestType.sans(13, color: RestPalette.accent),
          ),
        ],
      ],
    );
  }
}
