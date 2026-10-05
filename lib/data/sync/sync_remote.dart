import 'package:supabase_flutter/supabase_flutter.dart';

/// Wat de synchronisatie van de server nodig heeft. Houdt Supabase buiten de
/// engine, zodat tests een nep-server kunnen gebruiken.
abstract interface class SyncRemote {
  /// Zorgt voor een sessie, zodat de server `user_id` kan vullen.
  Future<void> ensureSignedIn();

  /// Voegt rijen toe of werkt ze bij op `id`.
  Future<void> upsert(String table, List<Map<String, Object?>> rows);
}

/// De remote is er nog niet. Gooit altijd, zodat geen enkele rij per ongeluk
/// als verstuurd wordt gemarkeerd.
class SyncUnavailableError implements Exception {
  const SyncUnavailableError();

  @override
  String toString() => 'SyncUnavailableError';
}

class UnavailableSyncRemote implements SyncRemote {
  const UnavailableSyncRemote();

  @override
  Future<void> ensureSignedIn() => throw const SyncUnavailableError();

  @override
  Future<void> upsert(String table, List<Map<String, Object?>> rows) =>
      throw const SyncUnavailableError();
}

/// Supabase-implementatie. Meldt zich anoniem aan als er nog geen sessie is.
class SupabaseSyncRemote implements SyncRemote {
  SupabaseSyncRemote(this._client);

  final SupabaseClient _client;

  @override
  Future<void> ensureSignedIn() async {
    if (_client.auth.currentSession == null) {
      await _client.auth.signInAnonymously();
    }
  }

  @override
  Future<void> upsert(String table, List<Map<String, Object?>> rows) async {
    await _client.from(table).upsert(rows, onConflict: 'id');
  }
}
