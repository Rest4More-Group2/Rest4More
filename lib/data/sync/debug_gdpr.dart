import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/sync_providers.dart';
import 'sync_remote.dart';

/// Probeert export of verwijdering op de echte server. Alleen voor debugbuilds,
/// bedoeld om de serverfuncties te testen voordat er een scherm is.
///
/// `export`: pusht eerst alles en toont daarna hoeveel rijen de server per
/// tabel teruggeeft. `delete`: doet hetzelfde, wist daarna alles in de cloud en
/// toont het resultaat. De inhoud van de gegevens wordt nooit gelogd.
Future<void> runDebugGdpr(ProviderContainer container, String mode) async {
  void log(String message) => debugPrint('[gdpr] $message');

  if (container.read(syncRemoteProvider) is UnavailableSyncRemote) {
    log('uit: geen Supabase');
    return;
  }
  if (mode != 'export' && mode != 'delete') {
    log('onbekende modus "$mode", gebruik export of delete');
    return;
  }

  final engine = container.read(syncEngineProvider);
  final service = container.read(cloudDataServiceProvider);
  try {
    final push = await engine.pushDirty();
    log('eerst gepusht: ok=${push.ok} pushed=${push.pushed} '
        'error=${push.error}');

    final json = await service.exportAsJson();
    final data = await container.read(syncRemoteProvider).exportMyData();
    final counts = {
      for (final entry in data.entries)
        if (entry.value is List) entry.key: (entry.value as List).length,
    };
    log('export ok, ${json.length} tekens, rijen per tabel: $counts');

    if (mode == 'delete') {
      await service.deleteCloudData();
      log('verwijderd. Controleer in het dashboard dat de rijen en de '
          'anonieme gebruiker weg zijn. Sync staat nu uit.');
    }
  } on Exception catch (error) {
    log('mislukt: $error');
  }
}
