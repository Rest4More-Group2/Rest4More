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

  /// Vergeet de laatste gelukte push.
  Future<void> clear();

  /// Id van het serveraccount waar de lokale gegevens het laatst naartoe
  /// zijn gestuurd.
  Future<String?> lastUserId();
  Future<void> saveUserId(String id);

  /// Vergeet het serveraccount, bijvoorbeeld nadat de cloudgegevens gewist zijn.
  Future<void> clearUserId();
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

  static const _userKey = 'sync_last_user_id';

  @override
  Future<String?> lastUserId() async =>
      (await SharedPreferences.getInstance()).getString(_userKey);

  @override
  Future<void> saveUserId(String id) async {
    await (await SharedPreferences.getInstance()).setString(_userKey, id);
  }

  @override
  Future<void> clearUserId() async {
    await (await SharedPreferences.getInstance()).remove(_userKey);
  }

  @override
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
    this.beforePush,
    this.pull,
  });

  final SyncEngine _engine;
  final SyncStateStore _store;
  final DateTime Function() _now;
  final Duration retryInterval;

  /// Loopt eerst, ongeacht de dagelijkse regel. Bedoeld voor het afmaken van een
  /// nog openstaande verwijdering van cloudgegevens. Mislukt het, dan wordt het
  /// later opnieuw geprobeerd.
  final Future<void> Function()? beforePush;

  /// Haalt eerst de wijzigingen van de server op, daarna wordt gepusht. Zo
  /// komt een leeg toestel eerst terug op de laatste stand. Mislukt het, dan
  /// wordt er niet gepusht en later opnieuw geprobeerd.
  final Future<void> Function()? pull;

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
      if (beforePush != null) {
        try {
          await beforePush!();
        } on Exception {
          _scheduleNext(retry: true);
          return;
        }
      }
      final today = LocalDate.format(_now());
      if (await _store.lastSuccessDate() == today) {
        _scheduleNext(retry: false);
        return;
      }
      if (pull != null) {
        try {
          await pull!();
        } on Exception {
          _scheduleNext(retry: true);
          return;
        }
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
      } else if (result.skippedNoConsent || result.skippedAgeGate) {
        // Geen toestemming of leeftijdsgrens: niets te doen, we kijken bij de
        // volgende start.
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
