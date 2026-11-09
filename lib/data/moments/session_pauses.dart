import '../database/converters.dart' show SessionEventData;
import '../database/enums.dart';

/// Een periode waarin de apps tijdelijk vrij waren. De timer van de sessie
/// staat dan stil, zodat die tijd niet als focustijd telt.
class SessionPause {
  const SessionPause({required this.start, required this.until, this.endedAt});

  final DateTime start;

  /// Tot wanneer de apps vrij zijn gegeven. Daarna gaan ze vanzelf weer dicht.
  final DateTime until;

  /// Als de gebruiker de apps eerder weer heeft dichtgezet.
  final DateTime? endedAt;

  /// Wanneer de pauze echt voorbij is (of zal zijn).
  DateTime get end {
    final early = endedAt;
    return early != null && early.isBefore(until) ? early : until;
  }

  Duration get length => end.difference(start);

  bool isActive(DateTime now) => !now.isBefore(start) && now.isBefore(end);

  SessionPause endedEarlyAt(DateTime at) =>
      SessionPause(start: start, until: until, endedAt: at);
}

/// Leest de pauzes uit het logboek van een sessie. Elke `unblockGranted` is
/// een pauze van zoveel minuten; een `unblockEnded` beëindigt elke pauze die
/// dan nog liep. Alles hangt aan tijdstippen, niet aan getelde seconden, dus
/// het klopt ook als de app dicht was toen de tijd om ging.
List<SessionPause> pausesFromEvents(Iterable<SessionEventData> events) {
  final pauses = <SessionPause>[];
  for (final e in events) {
    switch (e.event) {
      case SessionEventType.unblockGranted:
        final minutes = e.minutes;
        if (minutes == null || minutes <= 0) continue;
        pauses.add(
          SessionPause(
            start: e.at,
            until: e.at.add(Duration(minutes: minutes)),
          ),
        );
      case SessionEventType.unblockEnded:
        for (var i = 0; i < pauses.length; i++) {
          final p = pauses[i];
          if (p.endedAt == null && p.isActive(e.at)) {
            pauses[i] = p.endedEarlyAt(e.at);
          }
        }
      default:
        break;
    }
  }
  return pauses;
}

/// Hoe lang de timer tot [now] heeft stilgestaan. Pauzes die elkaar overlappen
/// (twee apps tegelijk vrij) tellen één keer.
Duration pausedUntil(Iterable<SessionPause> pauses, DateTime now) {
  final spans = [
    for (final p in pauses)
      if (p.start.isBefore(now)) (p.start, p.end.isBefore(now) ? p.end : now),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  var total = Duration.zero;
  DateTime? from;
  DateTime? to;
  for (final (start, end) in spans) {
    if (!end.isAfter(start)) continue;
    if (to == null || start.isAfter(to)) {
      if (to != null) total += to.difference(from!);
      from = start;
      to = end;
    } else if (end.isAfter(to)) {
      to = end;
    }
  }
  if (to != null) total += to.difference(from!);
  return total;
}
