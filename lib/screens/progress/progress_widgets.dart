import 'package:flutter/material.dart';
import 'package:rest4more/data/progress/progress_analytics.dart';
import 'package:rest4more/l10n/app_localizations.dart';
import 'package:rest4more/l10n/format.dart';

import '../today_screen.dart' show RestPalette, RestType;

/// Kleur voor "eerder gestopt" in grafieken: afgeleid van de huisstijl, met
/// genoeg contrast op [RestPalette.surface].
final Color progressMutedBar = Color.lerp(
  RestPalette.surface,
  RestPalette.ink,
  0.2,
)!;

/// Lichte achtergrond van een lege balk.
const Color progressTrack = RestPalette.background;

/// Kaart van het Progress-scherm.
class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.title,
    required this.children,
    this.highlighted = false,
  });

  final String title;
  final List<Widget> children;

  /// Voor het inzicht: warmere achtergrond en een rand in de hoofdkleur.
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: highlighted ? RestPalette.badge : RestPalette.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: highlighted ? RestPalette.accent : RestPalette.border,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: RestType.sans(15, color: RestPalette.accent)),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}

/// Een groot getal met een label erachter. Loopt bij grote letters door op een
/// volgende regel in plaats van buiten beeld.
class ProgressStat extends StatelessWidget {
  const ProgressStat(this.value, this.label, {super.key});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: MergeSemantics(
      child: Wrap(
        spacing: 10,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          Text(value, style: RestType.serif(34)),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(label, style: RestType.sans(14)),
          ),
        ],
      ),
    ),
  );
}

/// Twee of meer opties naast elkaar, één gekozen (This week | Patterns).
class ProgressSegmented<T> extends StatelessWidget {
  const ProgressSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.labelOf,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T) labelOf;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: RestPalette.surface,
      borderRadius: BorderRadius.circular(28),
    ),
    child: Row(
      children: [
        for (final option in options)
          Expanded(
            child: Semantics(
              button: true,
              selected: option == selected,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => onSelected(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  constraints: const BoxConstraints(minHeight: 44),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: option == selected
                        ? RestPalette.background
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    labelOf(option),
                    textAlign: TextAlign.center,
                    style: RestType.sans(
                      15,
                      color: option == selected
                          ? RestPalette.ink
                          : RestPalette.accent,
                      weight: option == selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Kleine wisselknoppen onderaan een kaart (Last week | Last 4 weeks).
class ProgressToggle<T> extends StatelessWidget {
  const ProgressToggle({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.labelOf,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T) labelOf;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final option in options)
        ChoiceChip(
          label: Text(labelOf(option)),
          selected: option == selected,
          onSelected: (_) => onSelected(option),
          showCheckmark: false,
          labelStyle: RestType.sans(
            13,
            color: option == selected ? RestPalette.ink : RestPalette.accent,
            weight: option == selected ? FontWeight.w600 : FontWeight.w400,
          ),
          selectedColor: RestPalette.background,
          backgroundColor: RestPalette.surface,
          side: const BorderSide(color: RestPalette.border),
          shape: const StadiumBorder(),
        ),
    ],
  );
}

/// Klein label met een verschil, zoals "+1" of "+35 min".
class ProgressPill extends StatelessWidget {
  const ProgressPill(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: RestPalette.badge,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: RestType.sans(13, color: RestPalette.primary, weight: FontWeight.w600),
    ),
  );
}

/// Een horizontale balk met label en aantal (When / Why).
class ProgressCountBar extends StatelessWidget {
  const ProgressCountBar({
    super.key,
    required this.label,
    required this.count,
    required this.max,
    this.emphasized = false,
  });

  final String label;
  final int count;
  final int max;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = emphasized ? RestPalette.primary : progressMutedBar;
    return Semantics(
      label: l10n.progressBucketCount(label, count),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: RestType.sans(
                      15,
                      weight: emphasized ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$count',
                  style: RestType.sans(
                    15,
                    color: emphasized ? RestPalette.primary : RestPalette.ink,
                    weight: emphasized ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: max == 0 ? 0 : count / max,
                minHeight: 8,
                color: color,
                backgroundColor: progressTrack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tijd als "21:00" of "9:00 PM", volgens de taal en de toestelinstelling.
String formatMinutesOfDay(BuildContext context, int minutes) =>
    TimeOfDay(hour: minutes ~/ 60 % 24, minute: minutes % 60).format(context);

/// "na 22:30", "voor 21:00" of "tussen 21:00 en 22:30", voor in een zin.
String bucketPhrase(
  BuildContext context,
  EveningBucket bucket,
  int eveningStartMinutes,
) {
  final l10n = AppLocalizations.of(context);
  final bounds = bucketBounds(eveningStartMinutes);
  final start = formatMinutesOfDay(context, bounds.start);
  final later = formatMinutesOfDay(context, bounds.laterFrom);
  return switch (bucket) {
    EveningBucket.before => l10n.progressWhenBefore(start),
    EveningBucket.firstPart => l10n.progressWhenBetween(start, later),
    EveningBucket.later => l10n.progressWhenAfter(later),
  };
}

/// Het label boven een balk: "Voor 21:00", "21:00 – 22:30", "Na 22:30".
String bucketLabel(
  BuildContext context,
  EveningBucket bucket,
  int eveningStartMinutes,
) {
  final l10n = AppLocalizations.of(context);
  final bounds = bucketBounds(eveningStartMinutes);
  final start = formatMinutesOfDay(context, bounds.start);
  final later = formatMinutesOfDay(context, bounds.laterFrom);
  return switch (bucket) {
    EveningBucket.before => l10n.progressBucketBefore(start),
    EveningBucket.firstPart => l10n.progressBucketBetween(start, later),
    EveningBucket.later => l10n.progressBucketAfter(later),
  };
}

/// "+1", "−1" of "gelijk". Met [minutes] als duur: "+35 min".
String deltaLabel(AppLocalizations l10n, int change, {bool minutes = false}) {
  if (change == 0) return l10n.progressNoChange;
  final sign = change > 0 ? '+' : '−';
  final value = minutes ? localizedDuration(l10n, change.abs()) : '${change.abs()}';
  return '$sign$value';
}

/// Eerste letter van een weekdag (M, T, W ...), in de gekozen taal.
String weekdayInitial(BuildContext context, int weekday) =>
    localizedWeekday(context, weekday).characters.first.toUpperCase();
