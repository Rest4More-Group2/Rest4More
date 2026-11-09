import 'package:rest4more/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_picker_screen.dart';
import 'today_screen.dart' show RestPalette, RestType;

/// Android: blocking apps needs the accessibility service. Once it is on, this
/// screen moves on to the app list by itself.
class AccessibilityAccessScreen extends StatefulWidget {
  const AccessibilityAccessScreen({super.key, this.next});

  /// Het scherm dat volgt zodra de service aan staat. Zonder: de oude, gedeelde
  /// appkiezer.
  final WidgetBuilder? next;

  @override
  State<AccessibilityAccessScreen> createState() =>
      _AccessibilityAccessScreenState();
}

class _AccessibilityAccessScreenState extends State<AccessibilityAccessScreen>
    with WidgetsBindingObserver {
  static const platform = MethodChannel(
    'com.example.app_blocking_prototype/blocking',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Coming back from the system settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkEnabled();
  }

  Future<void> _checkEnabled() async {
    try {
      final enabled =
          await platform.invokeMethod<bool>('isAccessibilityEnabled') ?? false;
      if (!enabled || !mounted) return;
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: widget.next ?? (_) => const AppPickerScreen(),
        ),
      );
    } catch (e) {
      debugPrint('Accessibility check error: $e');
    }
  }

  Future<void> _openSettings() async {
    try {
      await platform.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      debugPrint('Accessibility settings error: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: RestPalette.background,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: AppLocalizations.of(context).back,
                    style: IconButton.styleFrom(
                      backgroundColor: RestPalette.surface,
                      foregroundColor: RestPalette.primary,
                      minimumSize: const Size(44, 44),
                    ),
                    icon: const Icon(Icons.chevron_left),
                  ),
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
                    child: const Icon(Icons.accessibility_new,
                        color: RestPalette.primary, size: 28),
                  ),
                ),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context).allowAccessibility, style: RestType.serif(44)),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).accessibilityBody,
                  style: RestType.sans(17, color: RestPalette.accent),
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
                      Text(AppLocalizations.of(context).inSettings, style: RestType.serif(27)),
                      const SizedBox(height: 18),
                      _step(1, AppLocalizations.of(context).accStep1),
                      const SizedBox(height: 16),
                      _step(2, AppLocalizations.of(context).accStep2),
                      const SizedBox(height: 16),
                      _step(3, AppLocalizations.of(context).accStep3),
                    ],
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _openSettings,
                  style: FilledButton.styleFrom(
                    backgroundColor: RestPalette.primary,
                    foregroundColor: RestPalette.background,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    minimumSize: const Size(double.infinity, 58),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 26, vertical: 16),
                  ),
                  child: Row(
                    children: [
                      Text(AppLocalizations.of(context).openSettings, style: RestType.sans(17,
                          color: RestPalette.background,
                          weight: FontWeight.w600)),
                      const Spacer(),
                      const Icon(Icons.arrow_forward, size: 24),
                    ],
                  ),
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
        child: Text('$number', style: RestType.sans(13,
            color: RestPalette.primary, weight: FontWeight.w600)),
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
