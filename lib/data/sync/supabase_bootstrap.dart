import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_remote.dart';

const _url = String.fromEnvironment('SUPABASE_URL');
const _publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// Start Supabase met de waarden uit `--dart-define-from-file=env.json`.
/// Geeft null als die ontbreken of het starten mislukt: de app werkt dan
/// gewoon lokaal verder, zonder synchronisatie.
Future<SyncRemote?> initSupabaseRemote() async {
  final key = _publishableKey.isNotEmpty ? _publishableKey : _anonKey;
  if (_url.isEmpty || key.isEmpty) {
    if (kDebugMode) {
      debugPrint('[sync] uit: geen SUPABASE_URL of sleutel meegegeven '
          '(url leeg: ${_url.isEmpty}, sleutel leeg: ${key.isEmpty})');
    }
    return null;
  }
  try {
    await Supabase.initialize(url: _url, publishableKey: key);
    return SupabaseSyncRemote(Supabase.instance.client);
  } on Exception catch (error) {
    if (kDebugMode) debugPrint('[sync] uit: Supabase starten mislukt: $error');
    return null;
  }
}
