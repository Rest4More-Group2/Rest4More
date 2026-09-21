import 'package:flutter/material.dart';
import 'package:rest4more/theme/app_color.dart';

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
          ],
        ),
      ),
    );
  }
}
