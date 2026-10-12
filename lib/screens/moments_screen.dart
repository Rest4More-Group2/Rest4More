import 'package:flutter/material.dart';

import 'today_screen.dart' show RestPalette, RestType;
import 'focus_moment_screen.dart';
import 'saved_moment_pages.dart';
import 'session_setup_screen.dart';
import 'tag_moment_screen.dart';
import 'moments_widgets.dart';

class MomentsScreen extends StatefulWidget {
  const MomentsScreen({super.key, this.onStartFocus});

  final VoidCallback? onStartFocus;

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> {
  String? _selected;

  void _open(String id, WidgetBuilder builder) {
    setState(() => _selected = id);
    Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: builder));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: RestPalette.background,
    body: SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Moments', style: RestType.serif(40)),
                const SizedBox(height: 8),
                Text(
                  'Choose a space for mindful space',
                  style: RestType.sans(
                    16,
                    color: RestPalette.accent,
                  ),
                ),
                const SizedBox(height: 32),
                _momentCard(
                  id: 'focus',
                  title: 'Focus',
                  iconIndex: 1,
                  description:
                      'Clear your mind to commit to a single quiet workflow.',
                  builder: (_) =>
                      FocusMomentScreen(onStartFocus: widget.onStartFocus),
                ),
                const SizedBox(height: 16),
                _momentCard(
                  id: 'reading',
                  title: 'Reading',
                  iconIndex: 2,
                  description: 'Keep distractions away while you read.',
                  builder: (_) => SessionSetupScreen(
                    kind: SessionKind.reading,
                    // Zelfde tijdelijke koppeling als Focus, tot de timer er is.
                    onStart: (setup) => Navigator.pushNamed(
                      context,
                      '/prototype',
                      arguments: setup.kind.moment,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _momentCard(
                  id: 'tag',
                  title: 'Tag',
                  iconIndex: 4,
                  description:
                      'Set your apps aside with a tap of your tag, and bring '
                      'them back with the same tap.',
                  builder: (_) => const TagMomentScreen(),
                ),
                const SizedBox(height: 16),
                _momentCard(
                  id: 'evening',
                  title: 'Evening',
                  iconIndex: 3,
                  description:
                      'Wind down and put your phone away before bed.',
                  builder: (_) => const SavedEveningScreen(),
                ),
                const SizedBox(height: 16),
                _momentCard(
                  id: 'morning',
                  title: 'Morning',
                  iconIndex: 0,
                  description: 'Start the day before your phone does.',
                  builder: (_) => const SavedMorningScreen(),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _momentCard({
    required String id,
    required String title,
    required int iconIndex,
    required String description,
    required WidgetBuilder builder,
  }) {
    final selected = _selected == id;
    return Semantics(
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: RestPalette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? RestPalette.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => setState(() => _selected = id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: RestType.serif(27).copyWith(
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      AnimatedScale(
                        scale: selected ? 1.12 : 1,
                        duration: const Duration(milliseconds: 220),
                        child: RestMomentIcon(
                          index: iconIndex,
                          color: RestPalette.primary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: RestType.sans(16, color: RestPalette.accent),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => _open(id, builder),
                      style: TextButton.styleFrom(
                        foregroundColor: RestPalette.primary,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 48),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Begin',
                            style: RestType.sans(
                              15,
                              color: RestPalette.primary,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right, size: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
