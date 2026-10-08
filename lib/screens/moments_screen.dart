import 'package:flutter/material.dart';

import 'today_screen.dart' show RestPalette, RestType;
import 'focus_moment_screen.dart';
import 'tag_moment_screen.dart';
import 'moments_widgets.dart';

class MomentsScreen extends StatefulWidget {
  const MomentsScreen({super.key, this.onStartFocus});

  final VoidCallback? onStartFocus;

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> {
  bool _focusSelected = false;
  bool _tagSelected = false;

  void _beginFocus() {
    setState(() => _focusSelected = true);

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => FocusMomentScreen(
          onStartFocus: widget.onStartFocus,
        ),
      ),
    );
  }

  void _beginTag() {
    setState(() => _tagSelected = true);

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const TagMomentScreen()),
    );
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
                  title: 'Focus',
                  description:
                      'Clear your mind to commit to a single quiet workflow.',
                  iconIndex: 1,
                  selected: _focusSelected,
                  onSelect: () => setState(() => _focusSelected = true),
                  onBegin: _beginFocus,
                ),
                const SizedBox(height: 16),
                _momentCard(
                  title: 'Tag',
                  description:
                      'Set your apps aside with a tap of your tag, and bring '
                      'them back with the same tap.',
                  iconIndex: 4,
                  selected: _tagSelected,
                  onSelect: () => setState(() => _tagSelected = true),
                  onBegin: _beginTag,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _momentCard({
    required String title,
    required String description,
    required int iconIndex,
    required bool selected,
    required VoidCallback onSelect,
    required VoidCallback onBegin,
  }) {
    return Semantics(
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: RestPalette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? RestPalette.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onSelect,
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
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
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
                    style: RestType.sans(
                      16,
                      color: RestPalette.accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: onBegin,
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
                          const Icon(
                            Icons.chevron_right,
                            size: 24,
                          ),
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