import '../database/app_database.dart';
import '../database/converters.dart' show SessionEventData;
import '../database/enums.dart';
import '../repositories/focus_session_repository.dart';
import '../repositories/repository_support.dart';
import 'moment_blocking.dart';
import 'moment_profiles.dart';

/// Een lopende sessie met timer.
class RunningSession {
  const RunningSession({
    required this.id,
    required this.kind,
    required this.startedAt,
    required this.endsAt,
  });

  final String id;
  final MomentKind kind;
  final DateTime startedAt;

  /// Het eindtijdstip. De resterende tijd wordt hieruit berekend en niet
  /// afgeteld, zodat de klok klopt als de app even is opgeschort.
  final DateTime endsAt;

  Duration get total => endsAt.difference(startedAt);

  Duration remaining(DateTime now) {
    final left = endsAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  bool isOver(DateTime now) => !now.isBefore(endsAt);
}

/// Er loopt al een andere sessie. Die wordt nooit stil overschreven.
class SessionRunningError implements Exception {
  const SessionRunningError(this.running);

  final RunningSession running;

  @override
  String toString() => 'SessionRunningError: ${running.kind.name}';
}

/// Blokkeren is niet gelukt. De sessie is dan afgesloten als mislukt.
class SessionStartError implements Exception {
  const SessionStartError(this.cause);

  final Object cause;

  @override
  String toString() => 'SessionStartError: $cause';
}

/// De sessie is afgesloten, maar de apps zijn niet vrijgegeven.
class ReleaseFailedError implements Exception {
  const ReleaseFailedError(this.cause);

  final Object cause;

  @override
  String toString() => 'ReleaseFailedError: $cause';
}

/// Start en beëindigt sessies met timer (Focus en Reading).
///
/// Een sessie wordt pas `active` nadat blokkeren echt gelukt is. De timer
/// loopt hier alleen zolang de app open is; het beëindigen terwijl de app
/// dicht is hoort bij het onderdeel dat de timer op het toestel zelf zet.
class SessionRunner {
  SessionRunner(
    this._sessions,
    this._blocking, {
    this._now = DateTime.now,
    SessionPlatform? platform,
  }) : _platform = platform ?? SessionPlatform.unknown;

  final FocusSessionRepository _sessions;
  final MomentBlocking _blocking;
  final Clock _now;
  final SessionPlatform _platform;

  MomentKind? _kindOf(String mode) {
    for (final kind in MomentKind.values) {
      if (kind.name == mode) return kind;
    }
    return null;
  }

  RunningSession? _asRunning(FocusSession s) {
    final kind = _kindOf(s.mode);
    final seconds = s.plannedSeconds;
    if (kind == null || seconds == null) return null;
    return RunningSession(
      id: s.id,
      kind: kind,
      startedAt: s.startedAt,
      endsAt: s.startedAt.add(Duration(seconds: seconds)),
    );
  }

  /// De sessie die nu loopt, als die er is en actief is.
  Future<RunningSession?> current() async {
    final open = await _sessions.findOpen();
    if (open == null || open.state != SessionState.active) return null;
    return _asRunning(open);
  }

  /// Start een sessie. Loopt er al een, dan komt er een [SessionRunningError]
  /// en verandert er niets. Een oude, afgebroken sessie wordt eerst opgeruimd.
  Future<RunningSession> start({
    required MomentKind kind,
    required int minutes,
    String? blockProfileId,
  }) async {
    final open = await _sessions.findOpen();
    if (open != null) {
      final running = open.state == SessionState.active ? _asRunning(open) : null;
      if (running != null && !running.isOver(_now())) {
        throw SessionRunningError(running);
      }
      await _closeStale(open, running);
    }

    final session = await _sessions.start(
      mode: kind.name,
      source: SessionSource.manual,
      platform: _platform,
      blockProfileId: blockProfileId,
      plannedSeconds: minutes * 60,
    );
    await _sessions.transition(session.id, SessionState.activating);
    try {
      await _blocking.setBlocking(kind, true);
    } on Object catch (e) {
      await _sessions.finish(
        session.id,
        SessionOutcome.activationFailed,
        errorCode: 'activation_failed',
      );
      throw SessionStartError(e);
    }
    await _sessions.markBlockingConfirmed(session.id);
    await _sessions.transition(session.id, SessionState.active);
    final active = (await _sessions.findOpen())!;
    return _asRunning(active)!;
  }

  /// Beëindigt de sessie en geeft de apps vrij. [early] is true als de
  /// gebruiker eerder stopt; dat wordt als `stoppedEarly` vastgelegd.
  ///
  /// Mislukt het vrijgeven, dan staat de sessie als `releaseFailed` in het
  /// logboek en gooit dit een [ReleaseFailedError], zodat de aanroeper de
  /// gebruiker kan laten opnieuw proberen met [releaseBlocking].
  Future<void> end(RunningSession session, {required bool early}) async {
    await _sessions.transition(session.id, SessionState.releasing);
    try {
      await _blocking.setBlocking(session.kind, false);
      await _sessions.markBlockingReleased(session.id);
    } on Object catch (e) {
      await _sessions.finish(
        session.id,
        SessionOutcome.releaseFailed,
        errorCode: 'release_failed',
      );
      throw ReleaseFailedError(e);
    }
    await _sessions.finish(
      session.id,
      early ? SessionOutcome.stoppedEarly : SessionOutcome.completed,
    );
  }

  /// Legt vast dat de gebruiker tijdens de sessie een app [minutes] minuten
  /// heeft vrijgegeven. De sessie blijft gewoon doorlopen.
  Future<void> logUnblock(String sessionId, int minutes) =>
      _sessions.logEvent(
        sessionId,
        SessionEventData(
          at: _now().toUtc(),
          event: SessionEventType.unblockGranted,
          minutes: minutes,
        ),
      );

  /// Probeert de apps van [kind] opnieuw vrij te geven.
  Future<void> releaseBlocking(MomentKind kind) =>
      _blocking.setBlocking(kind, false);

  /// Ruimt een sessie op die niet meer loopt: afgebroken tijdens het starten,
  /// of verlopen terwijl de app dicht was.
  Future<void> _closeStale(FocusSession open, RunningSession? running) async {
    final kind = _kindOf(open.mode);
    switch (open.state) {
      case SessionState.selecting:
      case SessionState.awaitingScan:
      case SessionState.activating:
        await _sessions.finish(open.id, SessionOutcome.cancelled);
        if (kind != null && open.state == SessionState.activating) {
          // Blokkeren kan al aan staan: laat dat niet achter.
          await _blocking.setBlocking(kind, false);
        }
      default:
        if (open.state != SessionState.releasing) {
          await _sessions.transition(open.id, SessionState.releasing);
        }
        try {
          if (kind != null) await _blocking.setBlocking(kind, false);
          await _sessions.markBlockingReleased(open.id);
        } on Object {
          await _sessions.finish(
            open.id,
            SessionOutcome.releaseFailed,
            errorCode: 'release_failed',
          );
          return;
        }
        await _sessions.finish(
          open.id,
          running != null ? SessionOutcome.completed : SessionOutcome.cancelled,
        );
    }
  }
}
