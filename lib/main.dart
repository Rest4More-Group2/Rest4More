import 'package:flutter/material.dart';
import 'package:rest4more/theme/app_color.dart';

import 'screens/app_picker_screen.dart';
import 'screens/authorization_ios_screen.dart';
import 'screens/blocked_screen.dart';
import 'screens/home_screen.dart';
import 'screens/nfc_scan_screen.dart';
import 'screens/today_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rest For More',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.background,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const TodayScreen(),
        '/prototype': (context) =>
            const MyHomePage(title: 'AppBlock Prototype'),
        '/block': (context) => const BlockedScreen(),
        '/picker': (context) => const AppPickerScreen(),
        '/authorizationIOS': (context) =>
            const AuthorizationIosScreen(),
        '/nfcScan': (context) => const NfcScanScreen(),
      },
    );
  }
}