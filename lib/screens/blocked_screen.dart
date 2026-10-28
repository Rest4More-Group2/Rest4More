import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rest4more/theme/app_color.dart';

const _channel = MethodChannel('com.example.app_blocking_prototype/blocking');

class BlockedScreen extends StatelessWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.decoration,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, color: AppColors.background, size: 64),
            const SizedBox(height: 16),
            Text(
              'This app is blocked',
              style: TextStyle(color: AppColors.background, fontSize: 22),
            ),
            const SizedBox(height: 24),
            // Opent Rest For More, waar je de app bewust tijdelijk kunt
            // vrijgeven. Dit scherm draait in een eigen engine zonder database.
            OutlinedButton(
              onPressed: () async {
                try {
                  await _channel.invokeMethod<void>('openUnblock');
                } catch (_) {
                  // Het blokkeerscherm blijft gewoon staan.
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.background,
                side: BorderSide(color: AppColors.background),
                shape: const StadiumBorder(),
                minimumSize: const Size(48, 48),
              ),
              child: const Text('Open Rest For More'),
            ),
          ],
        ),
      ),
    );
  }
}
