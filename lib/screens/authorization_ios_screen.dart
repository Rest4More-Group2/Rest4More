import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      Navigator.pushReplacementNamed(context, '/picker');
    }
  }

  Future<void> _requestAuthorization() async {
    try {
      await platform.invokeMethod('requestAuthorization');
      await _checkStatus();
    } catch (e) {
      print('Authorization error: $e');
    }
  }

  Future<void> _openSettings() async {
    await platform.invokeMethod('openSettings');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screen Time Access')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_status == 'loading') const CircularProgressIndicator(),
              if (_status == 'notDetermined') ...[
                const Icon(Icons.shield_outlined, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'This app needs Screen Time access to block distracting apps.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _requestAuthorization,
                  child: const Text('Enable'),
                ),
              ],
              if (_status == 'denied') ...[
                const Icon(Icons.block, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Screen Time access was denied. Please enable it manually in Settings.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _openSettings,
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
