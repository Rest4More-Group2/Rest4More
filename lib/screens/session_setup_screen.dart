import 'package:rest4more/l10n/app_localizations.dart';
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
    presets: [
      FocusPreset('Quick', 25),
      FocusPreset('Standard', 45),
      FocusPreset('Deep', 90),
    ],
    defaultMinutes: 45,
  ),
  reading(
    presets: [
      FocusPreset('Short', 20),
      FocusPreset('Chapter', 40),
      FocusPreset('Long', 60),
    ],
    defaultMinutes: 40,
  );

  const SessionKind({
    required this.presets,
    required this.defaultMinutes,
  });

  String title(AppLocalizations l10n) => switch (this) {
        SessionKind.focus => l10n.momentFocusTitle,
        SessionKind.reading => l10n.momentReadingTitle,
      };

  String subtitle(AppLocalizations l10n) => switch (this) {
        SessionKind.focus => l10n.sessionFocusSubtitle,
        SessionKind.reading => l10n.sessionReadingSubtitle,
      };

  String startLabel(AppLocalizations l10n) => switch (this) {
        SessionKind.focus => l10n.startFocus,
        SessionKind.reading => l10n.startReading,
      };

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

  String localizedLabel(AppLocalizations l10n) => switch (label) {
        'Quick' => l10n.presetQuick,
        'Standard' => l10n.presetStandard,
        'Deep' => l10n.presetDeep,
        'Short' => l10n.presetShort,
        'Chapter' => l10n.presetChapter,
        'Long' => l10n.presetLong,
        _ => l10n.presetCustom,
      };
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
      title: kind.title(AppLocalizations.of(context)),
      subtitle: kind.subtitle(AppLocalizations.of(context)),
      bottom: MomentPrimaryButton(
        label: kind.startLabel(AppLocalizations.of(context)),
        onPressed: widget.onStart == null ? null : _start,
      ),
      children: [
        MomentSection(
          title: AppLocalizations.of(context).howLong,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChoiceChips<FocusPreset>(
                options: [...kind.presets, FocusPreset.custom],
                selected: _preset,
                onSelected: (p) => setState(() => _preset = p),
                labelOf: (p) => p.minutes == null
                    ? p.localizedLabel(AppLocalizations.of(context))
                    : '${p.localizedLabel(AppLocalizations.of(context))} · ${AppLocalizations.of(context).minutesShort(p.minutes!)}',
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
          note: AppLocalizations.of(context).endsAfterMinutes(_minutes),
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
            tooltip: AppLocalizations.of(context).fewerMinutes,
            onPressed: minutes <= minFocusMinutes
                ? null
                : () => onChanged(minutes - 5),
            icon: const Icon(Icons.remove),
          ),
          Expanded(
            child: Text(
              AppLocalizations.of(context).minutesShort(minutes),
              textAlign: TextAlign.center,
              style: RestType.serif(30),
            ),
          ),
          IconButton.outlined(
            tooltip: AppLocalizations.of(context).moreMinutes,
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
      title: Text(AppLocalizations.of(context).endSessionEarlyTitle, style: RestType.serif(26)),
      content: Text(
        AppLocalizations.of(context).endSessionEarlyBody,
        style: RestType.sans(15),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(AppLocalizations.of(context).keepGoing),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(AppLocalizations.of(context).endEarly),
        ),
      ],
    ),
  );
  return stop ?? false;
}
