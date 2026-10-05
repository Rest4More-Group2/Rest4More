import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/data/sync/debug_gdpr.dart';
import 'package:rest4more/data/sync/debug_seed.dart';
import 'package:rest4more/data/sync/supabase_bootstrap.dart';
import 'package:rest4more/data/sync/sync_scheduler.dart';
import 'package:rest4more/providers/database_providers.dart';
import 'package:rest4more/providers/repository_providers.dart';
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
  if (kDebugMode && remote != null) debugPrint('[sync] Supabase gestart');
  final container = ProviderContainer(
    overrides: [
      if (remote != null) syncRemoteProvider.overrideWithValue(remote),
    ],
  );
  if (kDebugMode && const bool.fromEnvironment('DEBUG_SYNC')) {
    // Alleen om de synchronisatie te testen voordat er een toestemmingsscherm
    // is: geef toestemming en vergeet dat er vandaag al gepusht is.
    await container
        .read(profileRepositoryProvider)
        .recordCloudSyncConsent(DateTime.now());
    await PreferencesSyncStateStore().clear();
    final seeded = await seedDebugData(container.read(databaseProvider));
    debugPrint('[sync] voorbeelddata aangemaakt: $seeded');
  }
  const gdprMode = String.fromEnvironment('DEBUG_GDPR');
  if (kDebugMode && gdprMode.isNotEmpty) {
    await runDebugGdpr(container, gdprMode);
  }
  // Bewaartermijn: oude zacht verwijderde rijen echt wissen.
  await container.read(retentionServiceProvider).purgeOldTombstones();
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
