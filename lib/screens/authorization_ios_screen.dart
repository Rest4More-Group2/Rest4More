import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'today_screen.dart' show RestPalette, RestType;

/// Asks for Screen Time access on iOS. Once it is approved, Apple's own app
/// picker opens straight away.
class AuthorizationIosScreen extends StatefulWidget {
  const AuthorizationIosScreen({super.key});

  @override
  State<AuthorizationIosScreen> createState() => _AuthorizationIosScreenState();
}

class _AuthorizationIosScreenState extends State<AuthorizationIosScreen>
    with WidgetsBindingObserver {
  static const platform = MethodChannel(
    'com.example.app_blocking_prototype/blocking',
  );

  String _status = 'loading';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Coming back from Settings after allowing access.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _status == 'denied') {
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    try {
      final result = await platform.invokeMethod<String>(
        'checkAuthorizationStatus',
      );
      if (!mounted) return;
      setState(() => _status = result ?? 'notDetermined');
    } catch (e) {
      debugPrint('Authorization error: $e');
      if (mounted) setState(() => _status = 'notDetermined');
      return;
    }

    if (_status == 'approved' && mounted) {
      await platform.invokeMethod('showAppPicker');
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _requestAuthorization() async {
    try {
      await platform.invokeMethod('requestAuthorization');
    } catch (e) {
      debugPrint('Authorization error: $e');
    }
    if (mounted) await _checkStatus();
  }

  Future<void> _openSettings() => platform.invokeMethod('openSettings');

  @override
  Widget build(BuildContext context) {
    final denied = _status == 'denied';

    return Scaffold(
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
                      tooltip: 'Back',
                      style: IconButton.styleFrom(
                        backgroundColor: RestPalette.surface,
                        foregroundColor: RestPalette.primary,
                        minimumSize: const Size(44, 44),
                      ),
                      icon: const Icon(Icons.chevron_left),
                    ),
                  ),
                  if (_status == 'loading' || _status == 'approved')
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                            color: RestPalette.primary),
                      ),
                    )
                  else ...[
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
                        child: Icon(
                          denied ? Icons.lock_outline : Icons.shield_outlined,
                          color: RestPalette.primary,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      denied ? 'Access is off' : 'Screen Time access',
                      style: RestType.serif(44),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      denied
                          ? 'Allow Screen Time access in Settings, then come '
                            'back to choose your apps.'
                          : 'Rest4More needs Screen Time access to set your '
                            'chosen apps aside. Your choices stay on this phone.',
                      style: RestType.sans(17, color: RestPalette.accent),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: denied ? _openSettings : _requestAuthorization,
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
                          Text(
                            denied ? 'Open Settings' : 'Allow access',
                            style: RestType.sans(17,
                                color: RestPalette.background,
                                weight: FontWeight.w600),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_forward, size: 24),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
