import 'package:flutter/material.dart';

import 'moments_widgets.dart';
import 'today_screen.dart' show RestPalette, RestType;

/// De tekst en het icoon van het openingsscherm van een moment.
class MomentIntro {
  const MomentIntro({
    required this.title,
    required this.description,
    required this.pill,
    required this.heading,
    required this.steps,
    required this.quote,
    required this.iconIndex,
    required this.buttonLabel,
  });

  final String title;
  final String description;

  /// Het korte label onder de beschrijving.
  final String pill;

  /// Kopje boven de drie stappen.
  final String heading;
  final List<String> steps;
  final String quote;
  final int iconIndex;
  final String buttonLabel;

  static const focus = MomentIntro(
    title: 'Focus',
    description: 'Clear your mind to commit to a single quiet workflow.',
    pill: 'A quiet place',
    heading: 'Settle into the moment',
    steps: [
      'Choose one meaningful task.',
      'Let your breath settle for three slow counts.',
      'Return gently whenever your attention wanders.',
    ],
    quote: 'One thing, fully attended.',
    iconIndex: 1,
    buttonLabel: 'Start Focus',
  );

  static const reading = MomentIntro(
    title: 'Reading',
    description: 'Keep distractions away while you read.',
    pill: 'One page at a time',
    heading: 'Settle into the moment',
    steps: [
      'Pick the book or article you want to read.',
      'Let your shoulders drop and breathe out slowly.',
      'When your mind drifts, return to the next line.',
    ],
    quote: 'One page, fully attended.',
    iconIndex: 2,
    buttonLabel: 'Start Reading',
  );

  static const evening = MomentIntro(
    title: 'Evening',
    description: 'Wind down and put your phone away before bed.',
    pill: 'A gentle landing',
    heading: 'Close the day',
    steps: [
      'Choose when you want to be in bed.',
      'Decide what your evening needs, and in what order.',
      'Let your phone rest while you wind down.',
    ],
    quote: 'The day is allowed to end.',
    iconIndex: 3,
    buttonLabel: 'Plan your evening',
  );

  static const morning = MomentIntro(
    title: 'Morning',
    description: 'Start the day before your phone does.',
    pill: 'A slow start',
    heading: 'Begin the day',
    steps: [
      'Choose when you wake up.',
      'Pick what your morning needs before your phone.',
      'Your phone returns when your morning is done.',
    ],
    quote: 'Your morning is yours first.',
    iconIndex: 0,
    buttonLabel: 'Plan your morning',
  );
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
                        intro.buttonLabel,
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
                          tooltip: 'Back to Moments',
                          style: IconButton.styleFrom(
                            backgroundColor: RestPalette.surface,
                            foregroundColor: RestPalette.primary,
                            minimumSize: const Size(44, 44),
                          ),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Moments',
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
                    Text(intro.title, style: RestType.serif(44)),
                    const SizedBox(height: 12),
                    Text(
                      intro.description,
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
                          intro.pill,
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
                          Text(intro.heading, style: RestType.serif(27)),
                          const SizedBox(height: 18),
                          for (var i = 0; i < intro.steps.length; i++) ...[
                            if (i > 0) const SizedBox(height: 16),
                            _step(i + 1, intro.steps[i]),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'A GENTLE REMINDER',
                      textAlign: TextAlign.center,
                      style: RestType.sans(
                        12,
                        color: RestPalette.accent,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '“${intro.quote}”',
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
