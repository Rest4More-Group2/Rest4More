/// Rekenwerk voor het Progress-scherm: weken, vergelijkingen en patronen.
///
/// Puur Dart: geen Flutter, geen database. Alles werkt op [MomentRecord]s en
/// lokale tijden, zodat het rekenwerk los te testen is. Widgets tonen alleen
/// wat hier uitkomt.
///
/// Regels die hier worden afgedwongen:
/// - Een patroon (of een zin die een patroon noemt) verschijnt pas vanaf
///   [minSample] momenten in de periode.
/// - Geen score en geen rangorde: alleen tellingen per groep.
/// - "Beschermde tijd" is alleen tijd waarin blokkeren aantoonbaar aan stond.
library;

import '../database/enums.dart' show EndReason;

/// Onder dit aantal momenten tonen we geen patronen of percentages.
const int minSample = 5;

/// Lengte van het eerste deel van de avond, vanaf de avondstart.
const int firstPartMinutes = 90;

/// Hoe lang "later op de avond" duurt, gerekend vanaf de avondstart. Wat
/// daarna komt tot aan de volgende avondstart telt als "voor de avond". Met
/// een avondstart van 21:00 loopt de avond zo tot 06:00, gelijk aan de grens
/// voor bedtijden na middernacht.
const int eveningLengthMinutes = 9 * 60;

/// Hoeveel eerder dan het late deel we een herinnering voorstellen.
const int reminderLeadMinutes = 30;

/// Eén moment zoals het rekenwerk het ziet. Tijden zijn lokaal.
class MomentRecord {
  const MomentRecord({
    required this.id,
    required this.start,
    required this.end,
    required this.endedEarly,
    required this.focused,
    required this.protected,
    required this.blocked,
    this.reason,
  });

  final String id;
  final DateTime start;
  final DateTime end;
  final bool endedEarly;

  /// Tijd van begin tot einde, zonder de pauzes waarin apps vrij waren.
  final Duration focused;

  /// Het deel van [focused] waarin blokkeren aantoonbaar aan stond.
  final Duration protected;

  /// Tijd dat blokkeren aan stond, zoals de Phone-away-kaart die telt:
  /// van bevestigd tot vrijgegeven, pauzes niet afgetrokken.
  final Duration blocked;
  final EndReason? reason;

  bool get completed => !endedEarly;
}

/// Kalenderdag zonder tijd.
DateTime dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

/// Eerste dag van de week waarin [day] valt. [weekStart] is een
/// `DateTime.weekday` (1 = maandag, 7 = zondag). Rekent met kalenderdagen,
/// niet met 24 uur, zodat zomer- en wintertijd niets verschuiven.
DateTime startOfWeek(DateTime day, int weekStart) {
  final back = (day.weekday - weekStart) % 7;
  return DateTime(day.year, day.month, day.day - back);
}

DateTime addDays(DateTime day, int days) =>
    DateTime(day.year, day.month, day.day + days);

/// Deel van de avond, gerekend vanaf de avondstart van de gebruiker.
enum EveningBucket { before, firstPart, later }

/// In welk deel van de avond [time] valt. [eveningStartMinutes] is in minuten
/// sinds middernacht. Een avond die over middernacht loopt (bijvoorbeeld
/// 01:00 bij een start van 21:00) valt in [EveningBucket.later].
EveningBucket bucketOf(DateTime time, int eveningStartMinutes) {
  final minutes = time.hour * 60 + time.minute;
  final offset = (minutes - eveningStartMinutes) % (24 * 60);
  if (offset < firstPartMinutes) return EveningBucket.firstPart;
  if (offset < eveningLengthMinutes) return EveningBucket.later;
  return EveningBucket.before;
}

/// Grenzen van de avonddelen in minuten sinds middernacht, voor labels.
({int start, int laterFrom}) bucketBounds(int eveningStartMinutes) => (
  start: eveningStartMinutes,
  laterFrom: (eveningStartMinutes + firstPartMinutes) % (24 * 60),
);

/// Tellingen over een periode.
class PeriodStats {
  const PeriodStats({
    required this.moments,
    required this.completed,
    required this.endedEarly,
    required this.protectedMinutes,
    required this.sessionMinutes,
    required this.blockedMinutes,
  });

  static const empty = PeriodStats(
    moments: 0,
    completed: 0,
    endedEarly: 0,
    protectedMinutes: 0,
    sessionMinutes: 0,
    blockedMinutes: 0,
  );

  final int moments;
  final int completed;
  final int endedEarly;

  /// Minuten waarin blokkeren aantoonbaar aan stond.
  final int protectedMinutes;

  /// Alle minuten van de momenten, beschermd of niet.
  final int sessionMinutes;

  /// Zie [MomentRecord.blocked].
  final int blockedMinutes;

  /// Minuten van momenten zonder bevestigde blokkade.
  int get unprotectedMinutes =>
      (sessionMinutes - protectedMinutes).clamp(0, sessionMinutes);

  factory PeriodStats.of(Iterable<MomentRecord> records) {
    var moments = 0, completed = 0, early = 0;
    var protected = Duration.zero,
        session = Duration.zero,
        blocked = Duration.zero;
    for (final r in records) {
      moments++;
      if (r.endedEarly) {
        early++;
      } else {
        completed++;
      }
      protected += r.protected;
      session += r.focused;
      blocked += r.blocked;
    }
    return PeriodStats(
      moments: moments,
      completed: completed,
      endedEarly: early,
      protectedMinutes: _minutes(protected),
      sessionMinutes: _minutes(session),
      blockedMinutes: _minutes(blocked),
    );
  }
}

int _minutes(Duration d) => (d.inSeconds / 60).round();

/// Minuten en aantallen van één dag in de staafgrafiek.
class DayBar {
  const DayBar({
    required this.date,
    required this.completedMinutes,
    required this.endedEarlyMinutes,
    required this.moments,
  });

  final DateTime date;
  final int completedMinutes;
  final int endedEarlyMinutes;
  final int moments;

  int get weekday => date.weekday;
  int get totalMinutes => completedMinutes + endedEarlyMinutes;
}

/// De positieve openingszin van de week. Nooit een oordeel: is er niets
/// beters te melden dan een daling, dan is er geen zin.
sealed class WeekWin {
  const WeekWin();
}

/// Meer momenten afgerond dan vorige week.
class MoreCompletedWin extends WeekWin {
  const MoreCompletedWin(this.completed, this.more);
  final int completed;
  final int more;
}

/// Meer beschermde tijd dan vorige week.
class MoreProtectedWin extends WeekWin {
  const MoreProtectedWin(this.minutes, this.moreMinutes);
  final int minutes;
  final int moreMinutes;
}

/// Minder vaak eerder gestopt dan vorige week.
class FewerEarlyWin extends WeekWin {
  const FewerEarlyWin(this.endedEarly, this.fewer);
  final int endedEarly;
  final int fewer;
}

/// Er is een moment afgerond, zonder vergelijking.
class CompletedWin extends WeekWin {
  const CompletedWin(this.completed);
  final int completed;
}

/// Eén gewone zin onder de grafiek.
sealed class WeekSentence {
  const WeekSentence();
}

/// Geen enkel moment stopte eerder.
class NoneEndedEarlySentence extends WeekSentence {
  const NoneEndedEarlySentence();
}

/// [count] van [of] vroege stops vielen in hetzelfde deel van de avond.
class EarlyInBucketSentence extends WeekSentence {
  const EarlyInBucketSentence({
    required this.bucket,
    required this.count,
    required this.of,
  });

  final EveningBucket bucket;
  final int count;
  final int of;

  bool get all => count == of;
}

/// Alles voor de weekkaart.
class WeekReport {
  const WeekReport({
    required this.start,
    required this.days,
    required this.stats,
    required this.previous,
    required this.win,
    required this.sentence,
    required this.hasAnyMoments,
    required this.isCurrentWeek,
    required this.canGoBack,
  });

  /// Eerste dag van de week.
  final DateTime start;

  /// Laatste dag van de week (inclusief).
  DateTime get end => addDays(start, 6);

  /// Zeven dagen, beginnend bij [start].
  final List<DayBar> days;
  final PeriodStats stats;
  final PeriodStats previous;
  final WeekWin? win;
  final WeekSentence? sentence;

  /// Of er ooit een moment is geweest. Zo niet: het lege beginscherm.
  final bool hasAnyMoments;
  final bool isCurrentWeek;
  final bool canGoBack;
}

enum ComparePeriod { lastWeek, last4Weeks }

/// Een getal nu en in de vorige periode.
class Delta {
  const Delta(this.current, this.previous);
  final int current;
  final int previous;
  int get change => current - previous;
}

class Comparison {
  const Comparison({
    required this.period,
    required this.completed,
    required this.protectedMinutes,
    required this.sessionMinutes,
    required this.endedEarly,
  });

  final ComparePeriod period;
  final Delta completed;
  final Delta protectedMinutes;
  final Delta sessionMinutes;
  final Delta endedEarly;

  /// Was er in een van beide periodes blokkeren actief? Anders tonen we
  /// sessietijd in plaats van beschermde tijd.
  bool get hasProtectedTime =>
      protectedMinutes.current > 0 || protectedMinutes.previous > 0;
}

/// Per weekdag: afgerond van totaal.
class WeekdayTally {
  const WeekdayTally(this.weekday, this.completed, this.total);
  final int weekday;
  final int completed;
  final int total;
}

/// Het meest voorkomende deel van de avond voor vroege stops.
class EarlyStopInsight {
  const EarlyStopInsight({
    required this.bucket,
    required this.count,
    required this.of,
    required this.suggestedReminderMinutes,
  });

  final EveningBucket bucket;
  final int count;
  final int of;

  /// Voor het late deel: een herinnering [reminderLeadMinutes] voor dat deel
  /// begint. Anders null.
  final int? suggestedReminderMinutes;

  /// Verandert als het inzicht verandert; zo komt een weggeklikt inzicht
  /// terug zodra er iets nieuws te zien is.
  String get signature => '${bucket.name}:$count/$of';
}

/// Weekend tegenover doordeweeks.
class WeekendNote {
  const WeekendNote({
    required this.harder,
    required this.completed,
    required this.total,
  });

  /// True als het weekend minder vaak lukt dan doordeweeks.
  final bool harder;
  final int completed;
  final int total;
}

/// Patronen over de laatste vier weken. Bij te weinig momenten zijn alle
/// patronen leeg en is [enoughData] false.
class PatternsReport {
  const PatternsReport._({
    required this.moments,
    required this.endedEarly,
    required this.enoughData,
    this.earlyByBucket = const {},
    this.reasons = const {},
    this.withReason = 0,
    this.weekdays = const [],
    this.insight,
    this.weekend,
  });

  final int moments;
  final int endedEarly;
  final bool enoughData;
  final Map<EveningBucket, int> earlyByBucket;

  /// Alleen redenen die minstens één keer voorkomen, in vaste volgorde.
  final Map<EndReason, int> reasons;
  final int withReason;
  final List<WeekdayTally> weekdays;
  final EarlyStopInsight? insight;
  final WeekendNote? weekend;
}

/// Het rekenwerk zelf. Houdt de instellingen en de klok vast; geeft voor elke
/// vraag van het scherm een rapport.
class ProgressAnalytics {
  ProgressAnalytics({
    required List<MomentRecord> records,
    required this.now,
    this.eveningStartMinutes = 21 * 60,
    this.weekStart = DateTime.monday,
  }) : records = ([...records]..sort((a, b) => a.start.compareTo(b.start)));

  final List<MomentRecord> records;
  final DateTime now;
  final int eveningStartMinutes;
  final int weekStart;

  static const patternDays = 28;

  DateTime get currentWeekStart => startOfWeek(dateOnly(now), weekStart);

  /// Momenten die begonnen op of na [from] en voor [until] (kalenderdagen).
  List<MomentRecord> between(DateTime from, DateTime until) => [
    for (final r in records)
      if (!r.start.isBefore(from) && r.start.isBefore(until)) r,
  ];

  PeriodStats statsForWeeks(DateTime from, int weeks) =>
      PeriodStats.of(between(from, addDays(from, 7 * weeks)));

  /// De week [weeksBack] weken voor de huidige (0 = deze week).
  WeekReport week(int weeksBack) {
    final start = addDays(currentWeekStart, -7 * weeksBack);
    final inWeek = between(start, addDays(start, 7));
    final stats = PeriodStats.of(inWeek);
    final previous = statsForWeeks(addDays(start, -7), 1);
    final first = records.isEmpty ? null : records.first.start;
    return WeekReport(
      start: start,
      days: [
        for (var i = 0; i < 7; i++) _dayBar(addDays(start, i), inWeek),
      ],
      stats: stats,
      previous: previous,
      win: _win(stats, previous),
      sentence: _sentence(inWeek),
      hasAnyMoments: records.isNotEmpty,
      isCurrentWeek: weeksBack <= 0,
      canGoBack: first != null && start.isAfter(dateOnly(first)),
    );
  }

  DayBar _dayBar(DateTime day, List<MomentRecord> inWeek) {
    final next = addDays(day, 1);
    var done = Duration.zero, early = Duration.zero, count = 0;
    for (final r in inWeek) {
      if (r.start.isBefore(day) || !r.start.isBefore(next)) continue;
      count++;
      if (r.endedEarly) {
        early += r.focused;
      } else {
        done += r.focused;
      }
    }
    return DayBar(
      date: day,
      completedMinutes: _minutes(done),
      endedEarlyMinutes: _minutes(early),
      moments: count,
    );
  }

  WeekWin? _win(PeriodStats now, PeriodStats before) {
    if (now.moments == 0) return null;
    if (before.moments > 0) {
      if (now.completed > before.completed) {
        return MoreCompletedWin(now.completed, now.completed - before.completed);
      }
      if (now.protectedMinutes > before.protectedMinutes &&
          before.protectedMinutes > 0) {
        return MoreProtectedWin(
          now.protectedMinutes,
          now.protectedMinutes - before.protectedMinutes,
        );
      }
      if (now.endedEarly < before.endedEarly) {
        return FewerEarlyWin(now.endedEarly, before.endedEarly - now.endedEarly);
      }
    }
    if (now.completed > 0) return CompletedWin(now.completed);
    return null;
  }

  WeekSentence? _sentence(List<MomentRecord> inWeek) {
    if (inWeek.length < minSample) return null;
    final early = inWeek.where((r) => r.endedEarly).toList();
    if (early.isEmpty) return const NoneEndedEarlySentence();
    final top = _topBucket(_byBucket(early));
    if (top == null) return null;
    // Alleen als het een duidelijke meerderheid is.
    if (top.count * 2 <= early.length) return null;
    return EarlyInBucketSentence(
      bucket: top.bucket,
      count: top.count,
      of: early.length,
    );
  }

  Map<EveningBucket, int> _byBucket(Iterable<MomentRecord> early) {
    final counts = {for (final b in EveningBucket.values) b: 0};
    for (final r in early) {
      final b = bucketOf(r.end, eveningStartMinutes);
      counts[b] = counts[b]! + 1;
    }
    return counts;
  }

  /// Het deel met de meeste stops, alleen als het strikt het grootste is.
  ({EveningBucket bucket, int count})? _topBucket(Map<EveningBucket, int> c) {
    EveningBucket? best;
    var bestCount = 0;
    var tie = false;
    for (final MapEntry(key: b, value: n) in c.entries) {
      if (n > bestCount) {
        best = b;
        bestCount = n;
        tie = false;
      } else if (n == bestCount && n > 0) {
        tie = true;
      }
    }
    if (best == null || tie) return null;
    return (bucket: best, count: bestCount);
  }

  /// Vergelijkt de week van [weeksBack] met de week ervoor, of de vier weken
  /// tot en met die week met de vier weken daarvoor.
  Comparison compare(int weeksBack, ComparePeriod period) {
    final weeks = period == ComparePeriod.lastWeek ? 1 : 4;
    final end = addDays(currentWeekStart, -7 * weeksBack + 7);
    final from = addDays(end, -7 * weeks);
    final now = statsForWeeks(from, weeks);
    final before = statsForWeeks(addDays(from, -7 * weeks), weeks);
    return Comparison(
      period: period,
      completed: Delta(now.completed, before.completed),
      protectedMinutes: Delta(now.protectedMinutes, before.protectedMinutes),
      sessionMinutes: Delta(now.sessionMinutes, before.sessionMinutes),
      endedEarly: Delta(now.endedEarly, before.endedEarly),
    );
  }

  /// Patronen over de laatste [patternDays] dagen, tot en met vandaag.
  PatternsReport patterns() {
    final today = dateOnly(now);
    final period = between(
      addDays(today, -(patternDays - 1)),
      addDays(today, 1),
    );
    final early = period.where((r) => r.endedEarly).toList();
    if (period.length < minSample) {
      return PatternsReport._(
        moments: period.length,
        endedEarly: early.length,
        enoughData: false,
      );
    }

    final byBucket = _byBucket(early);
    final reasons = <EndReason, int>{};
    for (final choice in EndReason.choices) {
      final n = early.where((r) => r.reason == choice).length;
      if (n > 0) reasons[choice] = n;
    }
    final withReason = early
        .where((r) => r.reason != null && r.reason != EndReason.unknown)
        .length;

    final weekdays = [
      for (var i = 0; i < 7; i++)
        () {
          final day = (weekStart - 1 + i) % 7 + 1;
          final onDay = period.where((r) => r.start.weekday == day);
          return WeekdayTally(
            day,
            onDay.where((r) => r.completed).length,
            onDay.length,
          );
        }(),
    ];

    return PatternsReport._(
      moments: period.length,
      endedEarly: early.length,
      enoughData: true,
      earlyByBucket: byBucket,
      reasons: reasons,
      withReason: withReason,
      weekdays: weekdays,
      insight: _insight(byBucket, early.length),
      weekend: _weekend(period),
    );
  }

  EarlyStopInsight? _insight(Map<EveningBucket, int> byBucket, int early) {
    final top = _topBucket(byBucket);
    if (top == null || top.count < 2) return null;
    return EarlyStopInsight(
      bucket: top.bucket,
      count: top.count,
      of: early,
      suggestedReminderMinutes: top.bucket == EveningBucket.later
          ? (eveningStartMinutes + firstPartMinutes - reminderLeadMinutes) %
                (24 * 60)
          : null,
    );
  }

  WeekendNote? _weekend(List<MomentRecord> period) {
    bool isWeekend(MomentRecord r) =>
        r.start.weekday == DateTime.saturday ||
        r.start.weekday == DateTime.sunday;
    final weekend = period.where(isWeekend).toList();
    final weekday = period.where((r) => !isWeekend(r)).toList();
    if (weekend.length < minSample || weekday.length < minSample) return null;
    final wkndDone = weekend.where((r) => r.completed).length;
    final wkdyDone = weekday.where((r) => r.completed).length;
    // Kruislings vergelijken, zonder afronding van percentages.
    final a = wkndDone * weekday.length;
    final b = wkdyDone * weekend.length;
    if (a == b) return null;
    return WeekendNote(
      harder: a < b,
      completed: wkndDone,
      total: weekend.length,
    );
  }
}
