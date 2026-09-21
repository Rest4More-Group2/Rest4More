import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rest4more/theme/app_color.dart';

class AuthorizationIosScreen extends StatefulWidget {
  const AuthorizationIosScreen({super.key});

  @override
  State<AuthorizationIosScreen> createState() => _AuthorizationIosScreenState();
}

class _AuthorizationIosScreenState extends State<AuthorizationIosScreen> {
  static const platform = MethodChannel(
    'com.example.app_blocking_prototype/blocking',
  );

  String _status = 'loading';

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final result = await platform.invokeMethod('checkAuthorizationStatus');
    setState(() {
      _status = result as String;
    });

    if (_status == 'approved' && mounted) {
      await platform.invokeMethod('showAppPicker');
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _requestAuthorization() async {
    try {
      await platform.invokeMethod('requestAuthorization');
      await _checkStatus();
    } catch (e) {
      debugPrint('Authorization error: $e');
    }
  }

  Future<void> _openSettings() async {
    await platform.invokeMethod('openSettings');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.decoration,
        foregroundColor: AppColors.background,
        title: const Text('Screen Time Access'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_status == 'loading')
                CircularProgressIndicator(color: AppColors.primaryAction),
              if (_status == 'notDetermined') ...[
                Icon(
                  Icons.shield_outlined,
                  size: 64,
                  color: AppColors.primaryAction,
                ),
                const SizedBox(height: 16),
                Text(
                  'This app needs Screen Time access to block distracting apps.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.text),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: _requestAuthorization,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryAction,
                    side: BorderSide(color: AppColors.primaryAction),
                  ),
                  child: const Text('Enable'),
                ),
              ],
              if (_status == 'denied') ...[
                Icon(Icons.block, size: 64, color: AppColors.accent),
                const SizedBox(height: 16),
                Text(
                  'Screen Time access was denied. Please enable it manually in Settings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.text),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: _openSettings,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryAction,
                    side: BorderSide(color: AppColors.primaryAction),
                  ),
                  child: const Text('Open Settings'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
