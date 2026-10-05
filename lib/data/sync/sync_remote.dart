import 'package:supabase_flutter/supabase_flutter.dart';

/// Wat de synchronisatie van de server nodig heeft. Houdt Supabase buiten de
/// engine, zodat tests een nep-server kunnen gebruiken.
abstract interface class SyncRemote {
  /// Zorgt voor een sessie, zodat de server `user_id` kan vullen.
  Future<void> ensureSignedIn();

  /// Id van de ingelogde gebruiker op de server, of null zonder sessie.
  String? get currentUserId;

  /// Laat de server weten dat dit account nog in gebruik is, zodat het niet
  /// als verlaten wordt opgeruimd.
  Future<void> recordActivity();

  /// Voegt rijen toe of werkt ze bij op `id`.
  Future<void> upsert(String table, List<Map<String, Object?>> rows);

  /// Haalt rijen op die na [after] zijn gewijzigd, gesorteerd op
  /// (`synced_at`, `id`), voor de pull. Zonder [after] begint het bij het begin.
  /// De rijen zijn de ruwe serverrijen, inclusief `synced_at`.
  Future<List<Map<String, Object?>>> fetchChanges(
    String table, {
    SyncPosition? after,
    int limit = 200,
  });

  /// Alle cloudgegevens van de gebruiker, voor het recht op inzage en
  /// overdraagbaarheid.
  Future<Map<String, Object?>> exportMyData();

  /// Wist alle cloudgegevens en het account op de server, en meldt lokaal af.
  Future<void> deleteMyData();
}

/// Positie in de wijzigingsvolgorde van de server.
class SyncPosition {
  const SyncPosition(this.syncedAt, this.id);

  /// `synced_at` zoals de server die teruggaf.
  final String syncedAt;
  final String id;
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
  String? get currentUserId => null;

  @override
  Future<void> recordActivity() => throw const SyncUnavailableError();

  @override
  Future<List<Map<String, Object?>>> fetchChanges(
    String table, {
    SyncPosition? after,
    int limit = 200,
  }) =>
      throw const SyncUnavailableError();

  @override
  Future<void> ensureSignedIn() => throw const SyncUnavailableError();

  @override
  Future<void> upsert(String table, List<Map<String, Object?>> rows) =>
      throw const SyncUnavailableError();

  @override
  Future<Map<String, Object?>> exportMyData() =>
      throw const SyncUnavailableError();

  @override
  Future<void> deleteMyData() => throw const SyncUnavailableError();
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
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<void> recordActivity() async {
    await _client.rpc('record_activity');
  }

  @override
  Future<List<Map<String, Object?>>> fetchChanges(
    String table, {
    SyncPosition? after,
    int limit = 200,
  }) async {
    var query = _client.from(table).select();
    if (after != null) {
      // Alles na de positie: later in tijd, of gelijk in tijd met een grotere id.
      query = query.or(
        'synced_at.gt.${after.syncedAt},'
        'and(synced_at.eq.${after.syncedAt},id.gt.${after.id})',
      );
    }
    final rows =
        await query.order('synced_at').order('id').limit(limit);
    return [for (final row in rows) Map<String, Object?>.from(row)];
  }

  @override
  Future<void> upsert(String table, List<Map<String, Object?>> rows) async {
    await _client.from(table).upsert(rows, onConflict: 'id');
  }

  @override
  Future<Map<String, Object?>> exportMyData() async {
    final result = await _client.rpc('export_my_data');
    return Map<String, Object?>.from(result as Map);
  }

  @override
  Future<void> deleteMyData() async {
    await _client.rpc('delete_my_data');
    // Het account bestaat niet meer, dus alleen de lokale sessie opruimen.
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } on Exception {
      // De server-kant is al gewist, een mislukte lokale afmelding is niet erg.
    }
  }
}
