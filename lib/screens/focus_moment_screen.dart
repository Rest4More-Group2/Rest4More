import 'package:flutter/material.dart';

import 'today_screen.dart' show RestPalette, RestType;
import 'moments_widgets.dart';

class FocusMomentScreen extends StatelessWidget {
  const FocusMomentScreen({super.key, this.onStartFocus});
  final VoidCallback? onStartFocus;

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
              onPressed:
                  onStartFocus ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'The focus session is not connected yet.',
                        ),
                      ),
                    );
                  },
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
                    'Start Focus',
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
                    child: const RestMomentIcon(
                      index: 1,
                      color: RestPalette.primary,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Focus', style: RestType.serif(44)),
                const SizedBox(height: 12),
                Text(
                  'Clear your mind to commit to a single quiet workflow.',
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
                      'A quiet place',
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
                      Text('Settle into the moment', style: RestType.serif(27)),
                      const SizedBox(height: 18),
                      _step(1, 'Choose one meaningful task.'),
                      const SizedBox(height: 16),
                      _step(2, 'Let your breath settle for three slow counts.'),
                      const SizedBox(height: 16),
                      _step(
                        3,
                        'Return gently whenever your attention wanders.',
                      ),
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
                  '“One thing, fully attended.”',
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
