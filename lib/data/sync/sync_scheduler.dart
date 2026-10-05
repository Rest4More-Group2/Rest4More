import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/local_types.dart';
import 'sync_engine.dart';

/// Bewaart op welke dag de laatste push is gelukt.
abstract interface class SyncStateStore {
  /// Lokale datum (`YYYY-MM-DD`) van de laatste gelukte push, of null.
  Future<String?> lastSuccessDate();
  Future<void> saveSuccessDate(String date);
}

class PreferencesSyncStateStore implements SyncStateStore {
  static const _key = 'sync_last_success_date';

  @override
  Future<String?> lastSuccessDate() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  @override
  Future<void> saveSuccessDate(String date) async {
    await (await SharedPreferences.getInstance()).setString(_key, date);
  }

  /// Vergeet de laatste gelukte push. Alleen voor testen.
  Future<void> clear() async {
    await (await SharedPreferences.getInstance()).remove(_key);
  }
}

/// Pusht hooguit een keer per dag.
///
/// Bij het openen van de app (en als de app weer naar voren komt) wordt er
/// gepusht als dat vandaag nog niet is gelukt. Mislukt het, dan probeert de
/// scheduler het later die dag opnieuw zolang de app open is. Zonder
/// toestemming voor synchronisatie gebeurt er niets en telt de dag niet mee.
class SyncScheduler {
  SyncScheduler(
    this._engine,
    this._store, {
    this._now = DateTime.now,
    this.retryInterval = const Duration(minutes: 30),
  });

  final SyncEngine _engine;
  final SyncStateStore _store;
  final DateTime Function() _now;
  final Duration retryInterval;

  Timer? _timer;
  bool _running = false;
  bool _stopped = false;

  /// Resultaat van de laatste poging, voor weergave of logging.
  PushResult? lastResult;

  /// Probeert te pushen als dat vandaag nog niet is gelukt.
  Future<void> maybePush() async {
    if (_stopped || _running) return;
    _running = true;
    try {
      final today = LocalDate.format(_now());
      if (await _store.lastSuccessDate() == today) {
        _scheduleNext(retry: false);
        return;
      }
      final result = await _engine.pushDirty();
      lastResult = result;
      if (kDebugMode) {
        debugPrint('[sync] ok=${result.ok} pushed=${result.pushed} '
            'noConsent=${result.skippedNoConsent} table=${result.failedTable} '
            'error=${result.error}');
      }
      if (result.ok) {
        await _store.saveSuccessDate(today);
        _scheduleNext(retry: false);
      } else if (result.skippedNoConsent) {
        // Geen toestemming: niets te doen, we kijken bij de volgende start.
      } else {
        _scheduleNext(retry: true);
      }
    } finally {
      _running = false;
    }
  }

  void _scheduleNext({required bool retry}) {
    _timer?.cancel();
    if (_stopped) return;
    final now = _now();
    final delay = retry
        ? retryInterval
        : DateTime(now.year, now.month, now.day + 1)
            .add(const Duration(minutes: 1))
            .difference(now);
    _timer = Timer(delay, maybePush);
  }

  void dispose() {
    _stopped = true;
    _timer?.cancel();
  }
}

/// Laat de scheduler opnieuw kijken als de app weer naar voren komt.
class SyncLifecycleObserver with WidgetsBindingObserver {
  SyncLifecycleObserver(this._scheduler);

  final SyncScheduler _scheduler;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _scheduler.maybePush();
  }
}
