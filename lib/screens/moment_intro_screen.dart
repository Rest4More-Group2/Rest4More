import 'package:rest4more/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'moments_widgets.dart';
import 'today_screen.dart' show RestPalette, RestType;

/// Welk moment een openingsscherm beschrijft.
enum MomentIntroKind { focus, reading, evening, morning }

/// De tekst en het icoon van het openingsscherm van een moment. De teksten
/// komen uit de vertalingen, dus ze worden pas bij het tonen opgehaald.
class MomentIntro {
  const MomentIntro._(this.kind, this.iconIndex);

  final MomentIntroKind kind;
  final int iconIndex;

  static const focus = MomentIntro._(MomentIntroKind.focus, 1);
  static const reading = MomentIntro._(MomentIntroKind.reading, 2);
  static const evening = MomentIntro._(MomentIntroKind.evening, 3);
  static const morning = MomentIntro._(MomentIntroKind.morning, 0);

  String title(AppLocalizations l10n) => switch (kind) {
      MomentIntroKind.focus => l10n.momentFocusTitle,
      MomentIntroKind.reading => l10n.momentReadingTitle,
      MomentIntroKind.evening => l10n.momentEveningTitle,
      MomentIntroKind.morning => l10n.momentMorningTitle,
      };

  String description(AppLocalizations l10n) => switch (kind) {
      MomentIntroKind.focus => l10n.momentFocusDescription,
      MomentIntroKind.reading => l10n.momentReadingDescription,
      MomentIntroKind.evening => l10n.momentEveningDescription,
      MomentIntroKind.morning => l10n.momentMorningDescription,
      };

  /// Het korte label onder de beschrijving.
  String pill(AppLocalizations l10n) => switch (kind) {
      MomentIntroKind.focus => l10n.momentFocusPill,
      MomentIntroKind.reading => l10n.momentReadingPill,
      MomentIntroKind.evening => l10n.momentEveningPill,
      MomentIntroKind.morning => l10n.momentMorningPill,
      };

  /// Kopje boven de drie stappen.
  String heading(AppLocalizations l10n) => switch (kind) {
      MomentIntroKind.focus => l10n.momentFocusHeading,
      MomentIntroKind.reading => l10n.momentReadingHeading,
      MomentIntroKind.evening => l10n.momentEveningHeading,
      MomentIntroKind.morning => l10n.momentMorningHeading,
      };

  List<String> steps(AppLocalizations l10n) => switch (kind) {
      MomentIntroKind.focus => [l10n.momentFocusStep1, l10n.momentFocusStep2, l10n.momentFocusStep3],
      MomentIntroKind.reading => [l10n.momentReadingStep1, l10n.momentReadingStep2, l10n.momentReadingStep3],
      MomentIntroKind.evening => [l10n.momentEveningStep1, l10n.momentEveningStep2, l10n.momentEveningStep3],
      MomentIntroKind.morning => [l10n.momentMorningStep1, l10n.momentMorningStep2, l10n.momentMorningStep3],
      };

  String quote(AppLocalizations l10n) => switch (kind) {
      MomentIntroKind.focus => l10n.momentFocusQuote,
      MomentIntroKind.reading => l10n.momentReadingQuote,
      MomentIntroKind.evening => l10n.momentEveningQuote,
      MomentIntroKind.morning => l10n.momentMorningQuote,
      };

  String buttonLabel(AppLocalizations l10n) => switch (kind) {
      MomentIntroKind.focus => l10n.momentFocusButton,
      MomentIntroKind.reading => l10n.momentReadingButton,
      MomentIntroKind.evening => l10n.momentEveningButton,
      MomentIntroKind.morning => l10n.momentMorningButton,
      };
}

/// Het openingsscherm van een moment. Zelfde opbouw voor Focus, Reading,
/// Evening en Morning: terug, icoon, titel, beschrijving, drie stappen en één
/// grote knop die naar de instellingen van het moment gaat.
class MomentIntroScreen extends StatelessWidget {
  const MomentIntroScreen({
    super.key,
    required this.intro,
    required this.next,
  });

  final MomentIntro intro;

  /// Het scherm waar de knop naartoe gaat.
  final WidgetBuilder next;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: RestPalette.background,
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: FilledButton(
                  onPressed: () => Navigator.of(context)
                      .push<void>(MaterialPageRoute<void>(builder: next)),
                  style: FilledButton.styleFrom(
                    backgroundColor: RestPalette.primary,
                    foregroundColor: RestPalette.background,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    minimumSize: const Size(double.infinity, 58),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 16,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        intro.buttonLabel(AppLocalizations.of(context)),
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
                ),
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
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          tooltip: AppLocalizations.of(context).backToMoments,
                          style: IconButton.styleFrom(
                            backgroundColor: RestPalette.surface,
                            foregroundColor: RestPalette.primary,
                            minimumSize: const Size(44, 44),
                          ),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context).tabMoments,
                          style: RestType.sans(
                            15,
                            color: RestPalette.primary,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: RestPalette.surface,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: RestMomentIcon(
                          index: intro.iconIndex,
                          color: RestPalette.primary,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(intro.title(AppLocalizations.of(context)), style: RestType.serif(44)),
                    const SizedBox(height: 12),
                    Text(
                      intro.description(AppLocalizations.of(context)),
                      style: RestType.sans(17, color: RestPalette.accent),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EEE5),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          intro.pill(AppLocalizations.of(context)),
                          style: RestType.sans(
                            14,
                            color: RestPalette.primary,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: RestPalette.surface,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(intro.heading(AppLocalizations.of(context)), style: RestType.serif(27)),
                          const SizedBox(height: 18),
                          for (var i = 0; i < intro.steps(AppLocalizations.of(context)).length; i++) ...[
                            if (i > 0) const SizedBox(height: 16),
                            _step(i + 1, intro.steps(AppLocalizations.of(context))[i]),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      AppLocalizations.of(context).aGentleReminder,
                      textAlign: TextAlign.center,
                      style: RestType.sans(
                        12,
                        color: RestPalette.accent,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '“${intro.quote(AppLocalizations.of(context))}”',
                      textAlign: TextAlign.center,
                      style: RestType.serif(24)
                          .copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _step(int number, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: RestPalette.background,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: RestType.sans(
                13,
                color: RestPalette.primary,
                weight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text, style: RestType.sans(15)),
            ),
          ),
        ],
      );
}
