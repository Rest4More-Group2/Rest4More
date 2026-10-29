import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/providers/notification_providers.dart';

import 'profile_tab.dart';
import 'today_screen.dart' show RestPalette, RestType;
import 'today_tab.dart';
import 'moments_screen.dart';
import 'moments_widgets.dart';

/// De app na de onboarding. Houdt ook de herinneringen voor de dagelijkse stap
/// bij: bsij het openen en elke keer dat de app terugkomt worden ze opnieuw
/// gepland (nieuwe dag, andere tijdzone, meldingen uitgezet). Een tik op een
/// herinnering opent Today.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, this.onStartStep, this.onStartFocus});
  final ValueChanged<int>? onStartStep;
  final VoidCallback? onStartFocus;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  static const _todayTab = 0;
  static const _progressTab = 2;

  int _selectedTab = _todayTab;
  StreamSubscription<int>? _taps;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final reminders = ref.read(reminderServiceProvider);
    reminders.sync();
    final scheduler = ref.read(reminderSchedulerProvider);
    _taps = scheduler.taps.listen(_openedFromReminder);
    scheduler.launchedFrom().then((id) {
      if (id != null) _openedFromReminder(id);
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _taps?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final reminders = ref.read(reminderServiceProvider);
    reminders.reconcileWithPermission().whenComplete(reminders.sync);
  }

  /// Een tik op een herinnering: naar de stap op Today, ook als er nog een
  /// scherm boven de app openstaat.
  void _openedFromReminder(int id) {
    ref.read(reminderServiceProvider).markOpened(id);
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() => _selectedTab = _todayTab);
  }

  void _selectTab(int index) {
    if (index == _progressTab) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress is not available yet.')),
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
        const SizedBox.shrink(), // Progress: not available yet
        const ProfileTab(),
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
