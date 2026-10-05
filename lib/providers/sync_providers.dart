import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync/sync_engine.dart';
import '../data/sync/sync_remote.dart';
import '../data/sync/sync_scheduler.dart';
import 'database_providers.dart';

/// Standaard is er geen server. Vervang dit door een `SupabaseSyncRemote` als
/// Supabase is geinitialiseerd.
final syncRemoteProvider =
    Provider<SyncRemote>((ref) => const UnavailableSyncRemote());

final syncEngineProvider = Provider(
  (ref) => SyncEngine(ref.watch(databaseProvider), ref.watch(syncRemoteProvider)),
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
