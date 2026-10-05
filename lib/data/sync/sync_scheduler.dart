import 'dart:async';

import '../database/app_database.dart';
import 'sync_engine.dart';

/// Start een push kort na elke lokale wijziging en bij het opstarten.
///
/// Wijzigingen worden gebundeld met een korte wachttijd, en er loopt nooit
/// meer dan een push tegelijk. Een mislukte push blijft liggen tot de volgende
/// wijziging, een handmatige [requestPush] of de volgende start.
class SyncScheduler {
  SyncScheduler(
    this._db,
    this._engine, {
    this.debounce = const Duration(seconds: 5),
  });

  final AppDatabase _db;
  final SyncEngine _engine;
  final Duration debounce;

  StreamSubscription<Object>? _subscription;
  Timer? _timer;
  bool _running = false;
  bool _again = false;
  bool _stopped = false;

  /// Resultaat van de laatste push, voor weergave of logging.
  PushResult? lastResult;

  void start() {
    if (_subscription != null) return;
    // De engine zet zelf `dirty` terug, dat levert ook wijzigingen op. Die
    // lopen vanzelf dood zodra er niets meer dirty is.
    _subscription = _db.tableUpdates().listen((_) => requestPush());
    requestPush();
  }

  void requestPush() {
    if (_stopped) return;
    _timer?.cancel();
    _timer = Timer(debounce, _run);
  }

  Future<void> _run() async {
    if (_stopped) return;
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      do {
        _again = false;
        lastResult = await _engine.pushDirty();
      } while (_again && !_stopped);
    } finally {
      _running = false;
    }
  }

  Future<void> dispose() async {
    _stopped = true;
    _timer?.cancel();
    await _subscription?.cancel();
  }
}
