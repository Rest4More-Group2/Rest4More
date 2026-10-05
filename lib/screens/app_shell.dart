import 'package:flutter/material.dart';

import 'today_screen.dart' show RestPalette, RestType;
import 'today_tab.dart';
import 'moments_screen.dart';
import 'moments_widgets.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.onStartStep, this.onStartFocus});
  final ValueChanged<int>? onStartStep;
  final VoidCallback? onStartFocus;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedTab = 0;

  void _selectTab(int index) {
    if (index > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${index == 2 ? 'Progress' : 'Profile'} is not available yet.',
          ),
        ),
      );
      return;
    }
    setState(() => _selectedTab = index);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: RestPalette.background,
    body: IndexedStack(
      index: _selectedTab,
      children: [
        TodayTab(onStartStep: widget.onStartStep),
        MomentsScreen(onStartFocus: widget.onStartFocus),
      ],
    ),
    bottomNavigationBar: DecoratedBox(
      decoration: const BoxDecoration(
        color: RestPalette.surface,
        border: Border(top: BorderSide(color: RestPalette.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
          child: Row(
            children: List.generate(4, (index) {
              const labels = ['Today', 'Moments', 'Progress', 'Profile'];
              final selected = index == _selectedTab;
              final color = selected ? RestPalette.primary : RestPalette.accent;
              return Expanded(
                child: Semantics(
                  selected: selected,
                  child: TextButton(
                    onPressed: () => _selectTab(index),
                    style: TextButton.styleFrom(
                      foregroundColor: color,
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 2,
                      ),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? RestPalette.primary.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedScale(
                            scale: selected ? 1.1 : 1,
                            duration: const Duration(milliseconds: 220),
                            child: RestMomentIcon(
                              index: index,
                              color: color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            labels[index],
                            style: RestType.sans(
                              11,
                              color: color,
                              weight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    ),
  );
}
