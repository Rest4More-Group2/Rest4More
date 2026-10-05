import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync/cloud_data_service.dart';
import '../data/sync/retention_service.dart';
import '../data/sync/sync_engine.dart';
import '../data/sync/sync_remote.dart';
import '../data/sync/sync_scheduler.dart';
import 'database_providers.dart';
import 'repository_providers.dart';

/// Standaard is er geen server. Vervang dit door een `SupabaseSyncRemote` als
/// Supabase is geinitialiseerd.
final syncRemoteProvider =
    Provider<SyncRemote>((ref) => const UnavailableSyncRemote());

final syncEngineProvider = Provider(
  (ref) => SyncEngine(
    ref.watch(databaseProvider),
    ref.watch(syncRemoteProvider),
    state: PreferencesSyncStateStore(),
  ),
);

/// Pusht hooguit een keer per dag, bij het openen van de app. Doet niets
/// zolang er geen echte remote is. Lees deze provider een keer bij het
/// opstarten.
final syncSchedulerProvider = Provider<SyncScheduler?>((ref) {
  if (ref.watch(syncRemoteProvider) is UnavailableSyncRemote) return null;
  final scheduler = SyncScheduler(
    ref.watch(syncEngineProvider),
    PreferencesSyncStateStore(),
  );
  final observer = SyncLifecycleObserver(scheduler);
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() {
    WidgetsBinding.instance.removeObserver(observer);
    scheduler.dispose();
  });
  scheduler.maybePush();
  return scheduler;
});

/// Export en verwijdering van de cloudgegevens.
final cloudDataServiceProvider = Provider(
  (ref) => CloudDataService(
    ref.watch(databaseProvider),
    ref.watch(syncRemoteProvider),
    PreferencesSyncStateStore(),
    ref.watch(profileRepositoryProvider),
  ),
);

/// Wist zacht verwijderde rijen na 2 jaar. Draai dit bij het opstarten.
final retentionServiceProvider =
    Provider((ref) => RetentionService(ref.watch(databaseProvider)));
