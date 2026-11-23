import 'package:shared_preferences/shared_preferences.dart';

import '../database/enums.dart';
import '../repositories/focus_session_repository.dart';
import '../repositories/repository_support.dart';
import 'moment_schedule.dart' show afterMidnightCutoffMinutes;

/// Waar het begin van een lopende strakke avond wordt onthouden, zodat het
/// ook na een herstart van de app bekend is.
abstract interface class StrictNightStash {
  Future<DateTime?> read();
  Future<void> write(DateTime startedAt);
  Future<void> clear();
}

class PrefsStrictNightStash implements StrictNightStash {
  static const _key = 'strict_night_started_at';

  @override
  Future<DateTime?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(_key);
    return text == null ? null : DateTime.tryParse(text);
  }

  @override
  Future<void> write(DateTime startedAt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, startedAt.toUtc().toIso8601String());
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// Een strakke avond stopt "eerder" als de kaart wordt gescand voor de
/// ochtendgrens (06:00) na het begin. Begint de avond na middernacht maar voor
/// 06:00, dan geldt 06:00 van diezelfde dag.
bool strictNightEndedEarly(DateTime startedAt, DateTime endedAt) {
  final start = startedAt.toLocal();
  final startMinutes = start.hour * 60 + start.minute;
  final dayOffset = startMinutes < afterMidnightCutoffMinutes ? 0 : 1;
  final cutoff = DateTime(
    start.year,
    start.month,
    start.day + dayOffset,
    afterMidnightCutoffMinutes ~/ 60,
    afterMidnightCutoffMinutes % 60,
  );
  return endedAt.toLocal().isBefore(cutoff);
}

/// Het resultaat van een vastgelegde strakke avond.
typedef StrictNightResult = ({String sessionId, bool endedEarly});

/// Legt strakke avonden vast als sessie, zonder iets aan de flow te veranderen:
/// [begin] als blokkeren aan staat, [end] nadat de kaart het heeft uitgezet.
class StrictNightLog {
  StrictNightLog(
    this._sessions,
    this._stash, {
    this._now = DateTime.now,
    SessionPlatform? platform,
  }) : _platform = platform ?? SessionPlatform.unknown;

  final FocusSessionRepository _sessions;
  final StrictNightStash _stash;
  final Clock _now;
  final SessionPlatform _platform;

  Future<void> begin() async {
    // Een oud begin (bijvoorbeeld van een avond die buiten de app eindigde)
    // wordt overschreven: alleen deze avond telt.
    await _stash.write(_now());
  }

  /// Null als er geen begin bekend is.
  Future<StrictNightResult?> end({required String mode}) async {
    final started = await _stash.read();
    if (started == null) return null;
    final ended = _now();
    final early = strictNightEndedEarly(started, ended);
    final session = await _sessions.recordFinished(
      mode: mode,
      source: SessionSource.nfc,
      platform: _platform,
      startedAt: started,
      endedAt: ended,
      outcome: early ? SessionOutcome.stoppedEarly : SessionOutcome.completed,
      blockingConfirmedAt: started,
      blockingReleasedAt: ended,
    );
    await _stash.clear();
    return (sessionId: session.id, endedEarly: early);
  }
}
