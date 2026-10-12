import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/data/moments/moment_profiles.dart';
import 'package:rest4more/providers/repository_providers.dart';

import 'moment_apps_section.dart';
import 'moments_form_widgets.dart';
import 'today_screen.dart' show RestPalette, RestType;

/// Soort sessie. Focus en Reading werken hetzelfde; ze verschillen in tekst,
/// duurkeuzes en welk opgeslagen app-profiel standaard gekozen is.
enum SessionKind {
  focus(
    title: 'Focus',
    subtitle: 'Pick how long, and what to keep out of the way.',
    startLabel: 'Start Focus',
    presets: [
      FocusPreset('Quick', 25),
      FocusPreset('Standard', 45),
      FocusPreset('Deep', 90),
    ],
    defaultMinutes: 45,
  ),
  reading(
    title: 'Reading',
    subtitle: 'Pick how long you want to read, and what stays quiet.',
    startLabel: 'Start Reading',
    presets: [
      FocusPreset('Short', 20),
      FocusPreset('Chapter', 40),
      FocusPreset('Long', 60),
    ],
    defaultMinutes: 40,
  );

  const SessionKind({
    required this.title,
    required this.subtitle,
    required this.startLabel,
    required this.presets,
    required this.defaultMinutes,
  });

  final String title;
  final String subtitle;
  final String startLabel;
  final List<FocusPreset> presets;
  final int defaultMinutes;

  MomentKind get moment => switch (this) {
        SessionKind.focus => MomentKind.focus,
        SessionKind.reading => MomentKind.reading,
      };
}

/// Vaste duur voor een sessie. [minutes] is null voor de eigen keuze.
class FocusPreset {
  const FocusPreset(this.label, this.minutes);
  static const custom = FocusPreset('Custom', null);

  final String label;
  final int? minutes;
}

/// Wat de gebruiker op het startscherm heeft gekozen.
class FocusSetup {
  const FocusSetup({
    required this.kind,
    required this.minutes,
    required this.blockProfileId,
  });

  final SessionKind kind;

  final int minutes;

  /// Het blokkeerprofiel van dit moment; wordt aangemaakt als het er nog niet is.
  final String blockProfileId;
}

const int minFocusMinutes = 5;
const int maxFocusMinutes = 240;

/// Startscherm van Focus en Reading: kies een voorinstelling, een duur en een profiel.
/// De sessie zelf (timer, einde zonder app) komt uit een ander onderdeel;
/// dit scherm geeft de keuze door via [onStart].
class SessionSetupScreen extends ConsumerStatefulWidget {
  const SessionSetupScreen({
    super.key,
    this.kind = SessionKind.focus,
    this.onStart,
  });

  final SessionKind kind;
  final ValueChanged<FocusSetup>? onStart;

  @override
  ConsumerState<SessionSetupScreen> createState() =>
      _SessionSetupScreenState();
}

class _SessionSetupScreenState extends ConsumerState<SessionSetupScreen> {
  late FocusPreset _preset = widget.kind.presets.firstWhere(
    (p) => p.minutes == widget.kind.defaultMinutes,
  );
  int _customMinutes = 30;

  int get _minutes => _preset.minutes ?? _customMinutes;

  Future<void> _start() async {
    final profile =
        await ref.read(momentProfileServiceProvider).ensure(widget.kind.moment);
    widget.onStart?.call(FocusSetup(
      kind: widget.kind,
      minutes: _minutes,
      blockProfileId: profile.id,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    return MomentPage(
      title: kind.title,
      subtitle: kind.subtitle,
      bottom: MomentPrimaryButton(
        label: kind.startLabel,
        onPressed: widget.onStart == null ? null : _start,
      ),
      children: [
        MomentSection(
          title: 'How long',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChoiceChips<FocusPreset>(
                options: [...kind.presets, FocusPreset.custom],
                selected: _preset,
                onSelected: (p) => setState(() => _preset = p),
                labelOf: (p) => p.minutes == null
                    ? p.label
                    : '${p.label} · ${p.minutes} min',
              ),
              if (_preset.minutes == null) ...[
                const SizedBox(height: 16),
                _MinutesStepper(
                  minutes: _customMinutes,
                  onChanged: (m) => setState(() => _customMinutes = m),
                ),
              ],
            ],
          ),
          note: 'Ends after $_minutes minutes. Stopping early asks you to '
              'confirm first and is logged as stopped early.',
        ),
        MomentAppsSection(kind: kind.moment),
      ],
    );
  }
}

class _MinutesStepper extends StatelessWidget {
  const _MinutesStepper({required this.minutes, required this.onChanged});

  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          IconButton.outlined(
            tooltip: 'Fewer minutes',
            onPressed: minutes <= minFocusMinutes
                ? null
                : () => onChanged(minutes - 5),
            icon: const Icon(Icons.remove),
          ),
          Expanded(
            child: Text(
              '$minutes min',
              textAlign: TextAlign.center,
              style: RestType.serif(30),
            ),
          ),
          IconButton.outlined(
            tooltip: 'More minutes',
            onPressed: minutes >= maxFocusMinutes
                ? null
                : () => onChanged(minutes + 5),
            icon: const Icon(Icons.add),
          ),
        ],
      );
}

/// Vraagt of de sessie echt eerder moet stoppen. Geeft true als de gebruiker
/// bevestigt. Wie dit aanroept logt de sessie dan als `stoppedEarly`.
Future<bool> confirmStopEarly(BuildContext context) async {
  final stop = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: RestPalette.background,
      title: Text('End this session early?', style: RestType.serif(26)),
      content: Text(
        'Your apps unlock now. This session will be logged as stopped early.',
        style: RestType.sans(15),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep going'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('End early'),
        ),
      ],
    ),
  );
  return stop ?? false;
}
