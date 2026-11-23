import '../database/app_database.dart';
import '../database/enums.dart';
import '../moments/session_pauses.dart';
import 'progress_analytics.dart';

/// Uitkomsten die als moment tellen. Afgebroken starts, mislukte activaties
/// en open sessies tellen niet mee.
const _completed = {SessionOutcome.completed};
const _endedEarly = {SessionOutcome.stoppedEarly, SessionOutcome.emergencyRelease};

/// Zet sessies uit de database om naar [MomentRecord]s in lokale tijd, met de
/// lokaal bewaarde reden voor eerder stoppen erbij.
List<MomentRecord> momentRecords(
  Iterable<FocusSession> sessions,
  Map<String, EndReason> reasons,
) => [
  for (final s in sessions)
    if (s.endedAt != null &&
        s.deletedAt == null &&
        (_completed.contains(s.outcome) || _endedEarly.contains(s.outcome)))
      _record(s, reasons[s.id]),
];

MomentRecord _record(FocusSession s, EndReason? reason) {
  final start = s.startedAt.toLocal();
  final end = s.endedAt!.toLocal();
  final pauses = pausesFromEvents(s.events);
  Duration paused(DateTime from, DateTime to) =>
      pausedUntil(pauses, to) - pausedUntil(pauses, from);
  Duration positive(Duration d) => d.isNegative ? Duration.zero : d;

  final focused = positive(end.difference(start) - paused(start, end));

  var protected = Duration.zero;
  var blocked = Duration.zero;
  final confirmed = s.blockingConfirmedAt?.toLocal();
  if (confirmed != null) {
    final released = (s.blockingReleasedAt ?? s.endedAt)!.toLocal();
    blocked = positive(released.difference(confirmed));
    // Beschermd is de overlap van de blokkade met het moment, zonder pauzes.
    final from = confirmed.isAfter(start) ? confirmed : start;
    final to = released.isBefore(end) ? released : end;
    if (to.isAfter(from)) {
      protected = positive(to.difference(from) - paused(from, to));
    }
  }

  return MomentRecord(
    id: s.id,
    start: start,
    end: end,
    endedEarly: _endedEarly.contains(s.outcome),
    focused: focused,
    protected: protected,
    blocked: blocked,
    reason: reason,
  );
}
