import 'package:flutter/material.dart';

import 'today_screen.dart' show RestPalette, RestType;

/// Pagina met terugknop, titel en een scrollbare inhoud. Gedeeld door de
/// Focus-, Avond- en Ochtendpagina's.
class MomentPage extends StatelessWidget {
  const MomentPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.bottom,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  /// Vaste actie onderaan, bijvoorbeeld de startknop.
  final Widget? bottom;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: RestPalette.background,
        bottomNavigationBar: bottom == null
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: bottom,
                    ),
                  ),
                ),
              ),
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        tooltip: 'Back',
                        style: IconButton.styleFrom(
                          backgroundColor: RestPalette.surface,
                          foregroundColor: RestPalette.primary,
                          minimumSize: const Size(44, 44),
                        ),
                        icon: const Icon(Icons.chevron_left),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(title, style: RestType.serif(40)),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: RestType.sans(16, color: RestPalette.accent),
                    ),
                    const SizedBox(height: 24),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

/// Kaart met een kopje, voor een groep instellingen.
class MomentSection extends StatelessWidget {
  const MomentSection({
    super.key,
    required this.title,
    required this.child,
    this.note,
  });

  final String title;
  final Widget child;

  /// Korte uitleg onder de inhoud.
  final String? note;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: RestPalette.surface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: RestType.serif(24)),
              const SizedBox(height: 14),
              child,
              if (note != null) ...[
                const SizedBox(height: 12),
                Text(
                  note!,
                  style: RestType.sans(13, color: RestPalette.accent),
                ),
              ],
            ],
          ),
        ),
      );
}

/// Rij met keuzeknoppen waarvan er één is geselecteerd.
class ChoiceChips<T> extends StatelessWidget {
  const ChoiceChips({
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
                14,
                color: option == selected
                    ? RestPalette.background
                    : RestPalette.primary,
                weight: FontWeight.w600,
              ),
              selectedColor: RestPalette.primary,
              backgroundColor: RestPalette.background,
              side: const BorderSide(color: RestPalette.border),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            ),
        ],
      );
}

/// Knop met een tijd die een tijdkiezer opent.
class TimeButton extends StatelessWidget {
  const TimeButton({
    super.key,
    required this.minutes,
    required this.onChanged,
    this.enabled = true,
  });

  final int minutes;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return OutlinedButton(
      onPressed: !enabled
          ? null
          : () async {
              final picked = await showTimePicker(
                context: context,
                initialTime:
                    TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                ),
              );
              if (picked != null) onChanged(picked.hour * 60 + picked.minute);
            },
      style: OutlinedButton.styleFrom(
        foregroundColor: RestPalette.primary,
        side: const BorderSide(color: RestPalette.border),
        backgroundColor: RestPalette.background,
        shape: const StadiumBorder(),
        minimumSize: const Size(84, 44),
      ),
      child: Text(
        '$h:$m',
        style: RestType.sans(
          16,
          color: RestPalette.primary,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Rij in een weekschema: schakelaar, dagnaam en tijd.
class WeekdayTimeRow extends StatelessWidget {
  const WeekdayTimeRow({
    super.key,
    required this.name,
    required this.enabled,
    required this.minutes,
    required this.onEnabled,
    required this.onMinutes,
    this.hint,
  });

  final String name;
  final bool enabled;
  final int minutes;
  final ValueChanged<bool> onEnabled;
  final ValueChanged<int> onMinutes;

  /// Kleine regel onder de naam, bijvoorbeeld "after midnight".
  final String? hint;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Switch(
              value: enabled,
              onChanged: onEnabled,
              activeThumbColor: RestPalette.background,
              activeTrackColor: RestPalette.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: RestType.sans(
                      15,
                      weight: FontWeight.w600,
                      color: enabled ? RestPalette.ink : RestPalette.accent,
                    ),
                  ),
                  if (hint != null && enabled)
                    Text(
                      hint!,
                      style: RestType.sans(12, color: RestPalette.accent),
                    ),
                ],
              ),
            ),
            TimeButton(
              minutes: minutes,
              onChanged: onMinutes,
              enabled: enabled,
            ),
          ],
        ),
      );
}

/// Eén regel in een tijdlijn: tijd, titel en uitleg.
class TimelineRow extends StatelessWidget {
  const TimelineRow({
    super.key,
    required this.time,
    required this.title,
    this.detail,
    this.last = false,
  });

  final String time;
  final String title;
  final String? detail;
  final bool last;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              child: Text(
                time,
                style: RestType.sans(
                  15,
                  color: RestPalette.primary,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: RestPalette.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(width: 2, color: RestPalette.border),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: RestType.sans(15, weight: FontWeight.w600),
                    ),
                    if (detail != null)
                      Text(
                        detail!,
                        style: RestType.sans(13, color: RestPalette.accent),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

/// Grote ronde hoofdknop onderaan een pagina, in de stijl van "Start Focus".
class MomentPrimaryButton extends StatelessWidget {
  const MomentPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: RestPalette.primary,
          foregroundColor: RestPalette.background,
          disabledBackgroundColor: RestPalette.surface,
          elevation: 0,
          shape: const StadiumBorder(),
          minimumSize: const Size(double.infinity, 58),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: RestType.sans(
                17,
                color: RestPalette.background,
                weight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward, size: 24),
          ],
        ),
      );
}
