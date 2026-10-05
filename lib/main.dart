import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/data/sync/supabase_bootstrap.dart';
import 'package:rest4more/providers/sync_providers.dart';
import 'package:rest4more/theme/app_color.dart';

import 'screens/app_picker_screen.dart';
import 'screens/authorization_ios_screen.dart';
import 'screens/blocked_screen.dart';
import 'screens/home_screen.dart';
import 'screens/nfc_scan_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final remote = await initSupabaseRemote();
  final container = ProviderContainer(
    overrides: [
      if (remote != null) syncRemoteProvider.overrideWithValue(remote),
    ],
  );
  // Start de synchronisatie. Zonder Supabase-gegevens doet dit niets.
  container.read(syncSchedulerProvider);
  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppBlock Prototype',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.background),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MyHomePage(title: 'AppBlock Prototype'),
        '/block': (context) => const BlockedScreen(),
        '/picker': (context) => const AppPickerScreen(),
        '/authorizationIOS': (context) => const AuthorizationIosScreen(),
        '/nfcScan': (context) => const NfcScanScreen(),
      },
    );
  }
}
