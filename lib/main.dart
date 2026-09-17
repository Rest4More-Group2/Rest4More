import 'package:flutter/material.dart';

import 'screens/app_picker_screen.dart';
import 'screens/authorization_ios_screen.dart';
import 'screens/blocked_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppBlock Prototype',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MyHomePage(title: 'AppBlock Prototype'),
        '/block': (context) => const BlockedScreen(),
        '/picker': (context) => const AppPickerScreen(),
        '/authorizationIOS': (context) => const AuthorizationIosScreen(),
      },
    );
  }
}
