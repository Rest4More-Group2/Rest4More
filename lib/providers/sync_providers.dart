import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync/sync_engine.dart';
import '../data/sync/sync_remote.dart';
import 'database_providers.dart';

/// Standaard is er geen server. Vervang dit door een `SupabaseSyncRemote` als
/// Supabase is geinitialiseerd.
final syncRemoteProvider =
    Provider<SyncRemote>((ref) => const UnavailableSyncRemote());

final syncEngineProvider = Provider(
  (ref) => SyncEngine(ref.watch(databaseProvider), ref.watch(syncRemoteProvider)),
);
