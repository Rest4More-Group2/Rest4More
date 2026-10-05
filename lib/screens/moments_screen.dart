import 'package:flutter/material.dart';

import 'today_screen.dart' show RestPalette, RestType;
import 'focus_moment_screen.dart';
import 'moments_widgets.dart';

class MomentsScreen extends StatefulWidget {
  const MomentsScreen({super.key, this.onStartFocus});

  final VoidCallback? onStartFocus;

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> {
  bool _focusSelected = false;

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
                _focusCard(),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _focusCard() {
    return Semantics(
      selected: _focusSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: RestPalette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _focusSelected
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
            onTap: () {
              setState(() => _focusSelected = true);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Focus',
                          style: RestType.serif(27).copyWith(
                            fontWeight: _focusSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      AnimatedScale(
                        scale: _focusSelected ? 1.12 : 1,
                        duration: const Duration(milliseconds: 220),
                        child: const RestMomentIcon(
                          index: 1,
                          color: RestPalette.primary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Clear your mind to commit to a single quiet workflow.',
                    style: RestType.sans(
                      16,
                      color: RestPalette.accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _beginFocus,
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