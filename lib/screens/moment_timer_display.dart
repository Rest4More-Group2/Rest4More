import 'package:flutter/material.dart';

import 'today_screen.dart' show RestPalette, RestType;

class MomentTimerDisplay extends StatelessWidget {
  const MomentTimerDisplay({
    super.key,
    required this.clockText,
    required this.semanticLabel,
    required this.progress,
    required this.barColor,
  });

  final String clockText;
  final String semanticLabel;
  final double progress;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: semanticLabel,
          excludeSemantics: true,
          child: Text(
            clockText,
            textAlign: TextAlign.center,
            style: RestType.serif(72),
          ),
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: RestPalette.surface,
            color: barColor,
          ),
        ),
      ],
    );
  }
}