import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/progress/progress_analytics.dart';

var _id = 0;

/// Een moment dat op [start] begint en [minutes] duurt.
MomentRecord rec(
  DateTime start,
  int minutes, {
  bool early = false,
  bool protected = true,
  EndReason? reason,
  DateTime? end,
}) {
  final length = Duration(minutes: minutes);
  return MomentRecord(
    id: 'm${_id++}',
    start: start,
    end: end ?? start.add(length),
    endedEarly: early,
    focused: length,
    protected: protected ? length : Duration.zero,
    blocked: protected ? length : Duration.zero,
    reason: reason,
  );
}

/// Woensdag 18 november 2026, 12:00. De week (vanaf maandag) begint op 16 nov.
final now = DateTime(2026, 11, 18, 12);

ProgressAnalytics analytics(
  List<MomentRecord> records, {
  int weekStart = DateTime.monday,
  int eveningStart = 21 * 60,
  DateTime? at,
}) => ProgressAnalytics(
  records: records,
  now: at ?? now,
  weekStart: weekStart,
  eveningStartMinutes: eveningStart,
);

void main() {
  group('weekgrenzen', () {
    test('maandag als eerste dag', () {
      expect(startOfWeek(DateTime(2026, 11, 18), DateTime.monday),
          DateTime(2026, 11, 16));
      expect(startOfWeek(DateTime(2026, 11, 16), DateTime.monday),
          DateTime(2026, 11, 16));
      expect(startOfWeek(DateTime(2026, 11, 22), DateTime.monday),
          DateTime(2026, 11, 16));
    });

    test('zondag als eerste dag', () {
      expect(startOfWeek(DateTime(2026, 11, 22), DateTime.sunday),
          DateTime(2026, 11, 22));
      expect(startOfWeek(DateTime(2026, 11, 21), DateTime.sunday),
          DateTime(2026, 11, 15));
    });

    test('over een maand- en jaargrens en de wintertijd heen', () {
      expect(startOfWeek(DateTime(2027, 1, 2), DateTime.monday),
          DateTime(2026, 12, 28));
      // Wintertijd ging in op zondag 25 oktober 2026.
      expect(startOfWeek(DateTime(2026, 10, 27), DateTime.monday),
          DateTime(2026, 10, 26));
      expect(addDays(DateTime(2026, 10, 24), 2), DateTime(2026, 10, 26));
    });

    test('een moment op zondag hoort bij een andere week als de week op '
        'zondag begint', () {
      final sunday = rec(DateTime(2026, 11, 22, 21), 30);
      final monday = analytics([sunday], at: DateTime(2026, 11, 22, 23));
      expect(monday.week(0).stats.moments, 1);
      expect(monday.week(0).start, DateTime(2026, 11, 16));

      final sundayStart = analytics(
        [sunday],
        weekStart: DateTime.sunday,
        at: DateTime(2026, 11, 22, 23),
      );
      expect(sundayStart.week(0).start, DateTime(2026, 11, 22));
      expect(sundayStart.week(0).stats.moments, 1);
      expect(sundayStart.week(1).stats.moments, 0);
      expect(sundayStart.week(0).days.first.weekday, DateTime.sunday);
    });
  });

  group('weekoverzicht', () {
    test('telt momenten, minuten per dag en beschermde tijd', () {
      final a = analytics([
        rec(DateTime(2026, 11, 16, 21), 45),
        rec(DateTime(2026, 11, 17, 21), 20, early: true),
        rec(DateTime(2026, 11, 17, 7), 10, protected: false),
        // Vorige week en volgende week tellen niet mee.
        rec(DateTime(2026, 11, 15, 21), 30),
        rec(DateTime(2026, 11, 23, 21), 30),
      ]);
      final w = a.week(0);
      expect(w.stats.moments, 3);
      expect(w.stats.completed, 2);
      expect(w.stats.endedEarly, 1);
      expect(w.stats.sessionMinutes, 75);
      expect(w.stats.protectedMinutes, 65);
      expect(w.stats.unprotectedMinutes, 10);
      expect(w.days, hasLength(7));
      expect(w.days[0].completedMinutes, 45);
      expect(w.days[1].completedMinutes, 10);
      expect(w.days[1].endedEarlyMinutes, 20);
      expect(w.days[1].moments, 2);
      expect(w.days[2].totalMinutes, 0);
      expect(w.previous.moments, 1);
    });

    test('een avond over middernacht telt op de dag waarop hij begon', () {
      final a = analytics([rec(DateTime(2026, 11, 16, 23, 30), 60)]);
      expect(a.week(0).days[0].completedMinutes, 60);
      expect(a.week(0).days[1].completedMinutes, 0);
    });

    test('lege staat: nog nooit een moment', () {
      final w = analytics(const []).week(0);
      expect(w.hasAnyMoments, isFalse);
      expect(w.stats.moments, 0);
      expect(w.win, isNull);
      expect(w.sentence, isNull);
      expect(w.canGoBack, isFalse);
      expect(w.isCurrentWeek, isTrue);
    });

    test('een week zonder momenten, terwijl er wel eerdere zijn', () {
      final a = analytics([rec(DateTime(2026, 11, 3, 21), 30)]);
      final w = a.week(0);
      expect(w.hasAnyMoments, isTrue);
      expect(w.stats.moments, 0);
      expect(w.win, isNull);
      expect(w.canGoBack, isTrue);
      // Terug tot en met de week van het eerste moment.
      expect(a.week(2).canGoBack, isFalse);
      expect(a.week(2).stats.moments, 1);
      expect(a.week(1).isCurrentWeek, isFalse);
    });
  });

  group('winst van de week', () {
    test('meer afgerond dan vorige week', () {
      final w = analytics([
        rec(DateTime(2026, 11, 10, 21), 30),
        rec(DateTime(2026, 11, 16, 21), 30),
        rec(DateTime(2026, 11, 17, 21), 30),
      ]).week(0);
      expect(w.win, isA<MoreCompletedWin>());
      final win = w.win as MoreCompletedWin;
      expect(win.completed, 2);
      expect(win.more, 1);
    });

    test('minder eerder gestopt, ook als er niet meer is afgerond', () {
      final w = analytics([
        rec(DateTime(2026, 11, 10, 21), 30),
        rec(DateTime(2026, 11, 11, 21), 30, early: true),
        rec(DateTime(2026, 11, 12, 21), 30, early: true),
        rec(DateTime(2026, 11, 16, 21), 10),
      ]).week(0);
      expect(w.win, isA<FewerEarlyWin>());
      expect((w.win as FewerEarlyWin).fewer, 2);
    });

    test('nooit een oordeel: bij alleen een daling geen vergelijking', () {
      final w = analytics([
        rec(DateTime(2026, 11, 10, 21), 60),
        rec(DateTime(2026, 11, 11, 21), 60),
        rec(DateTime(2026, 11, 16, 21), 30),
      ]).week(0);
      expect(w.win, isA<CompletedWin>());
    });

    test('alleen eerder gestopte momenten: geen winst', () {
      final w = analytics([
        rec(DateTime(2026, 11, 16, 21), 30, early: true),
      ]).week(0);
      expect(w.win, isNull);
    });
  });

  group('avonddelen', () {
    const start = 21 * 60;
    EveningBucket at(int h, int m, [int evening = start]) =>
        bucketOf(DateTime(2026, 11, 16, h, m), evening);

    test('voor de avond, het eerste deel en later', () {
      expect(at(20, 59), EveningBucket.before);
      expect(at(21, 0), EveningBucket.firstPart);
      expect(at(22, 29), EveningBucket.firstPart);
      expect(at(22, 30), EveningBucket.later);
      expect(at(14, 0), EveningBucket.before);
      expect(at(7, 30), EveningBucket.before);
    });

    test('een avond over middernacht blijft "later"', () {
      expect(at(0, 0), EveningBucket.later);
      expect(at(1, 30), EveningBucket.later);
      expect(at(5, 59), EveningBucket.later);
      expect(at(6, 0), EveningBucket.before);
    });

    test('een avondstart vlak voor middernacht (ploegendienst)', () {
      const late = 23 * 60;
      expect(at(22, 59, late), EveningBucket.before);
      expect(at(23, 30, late), EveningBucket.firstPart);
      expect(at(0, 29, late), EveningBucket.firstPart);
      expect(at(0, 30, late), EveningBucket.later);
      expect(at(7, 59, late), EveningBucket.later);
      expect(at(8, 0, late), EveningBucket.before);
    });

    test('grenzen voor de labels', () {
      expect(bucketBounds(start), (start: 21 * 60, laterFrom: 22 * 60 + 30));
      expect(bucketBounds(23 * 60), (start: 23 * 60, laterFrom: 30));
    });
  });

  group('minimale steekproef', () {
    List<MomentRecord> moments(int n, {bool early = true}) => [
      for (var i = 0; i < n; i++)
        rec(DateTime(2026, 11, 16 - i, 22, 40), 20, early: early),
    ];

    test('onder 5 momenten: geen patronen en geen zin', () {
      final a = analytics(moments(4));
      final p = a.patterns();
      expect(p.enoughData, isFalse);
      expect(p.moments, 4);
      expect(p.earlyByBucket, isEmpty);
      expect(p.reasons, isEmpty);
      expect(p.weekdays, isEmpty);
      expect(p.insight, isNull);
      expect(p.weekend, isNull);
    });

    test('vanaf 5 momenten wel', () {
      final p = analytics(moments(5)).patterns();
      expect(p.enoughData, isTrue);
      expect(p.earlyByBucket[EveningBucket.later], 5);
      expect(p.insight, isNotNull);
    });

    test('de zin onder de grafiek pas vanaf 5 momenten in de week', () {
      List<MomentRecord> week(int n) => [
        for (var i = 0; i < n; i++)
          rec(DateTime(2026, 11, 16, 8 + i), 20, early: i < 2,
              end: DateTime(2026, 11, 16, 23, i)),
      ];
      expect(analytics(week(4)).week(0).sentence, isNull);
      final s = analytics(week(5)).week(0).sentence;
      expect(s, isA<EarlyInBucketSentence>());
      final e = s as EarlyInBucketSentence;
      expect(e.bucket, EveningBucket.later);
      expect(e.count, 2);
      expect(e.all, isTrue);
    });

    test('alleen momenten van de laatste 28 dagen tellen', () {
      final a = analytics([
        ...moments(4),
        rec(DateTime(2026, 10, 21, 22), 20), // 28 dagen geleden: telt niet
        rec(DateTime(2026, 10, 22, 22), 20), // 27 dagen geleden: telt
      ]);
      expect(a.patterns().moments, 5);
    });
  });

  group('patronen', () {
    test('inzicht, redenen en voorgestelde herinnering', () {
      final p = analytics([
        rec(DateTime(2026, 11, 16, 20), 20,
            early: true, reason: EndReason.couldntSleep,
            end: DateTime(2026, 11, 16, 20, 30)),
        rec(DateTime(2026, 11, 15, 21), 20,
            early: true, reason: EndReason.neededPhone),
        rec(DateTime(2026, 11, 14, 22, 20), 20,
            early: true, reason: EndReason.couldntSleep),
        rec(DateTime(2026, 11, 13, 22, 40), 20, early: true),
        rec(DateTime(2026, 11, 12, 23, 50), 20,
            early: true, reason: EndReason.couldntSleep,
            end: DateTime(2026, 11, 13, 0, 10)),
        rec(DateTime(2026, 11, 11, 21), 30),
      ]).patterns();
      expect(p.endedEarly, 5);
      expect(p.earlyByBucket, {
        EveningBucket.before: 1,
        EveningBucket.firstPart: 1,
        EveningBucket.later: 3,
      });
      expect(p.reasons, {EndReason.couldntSleep: 3, EndReason.neededPhone: 1});
      expect(p.withReason, 4);
      final insight = p.insight!;
      expect(insight.bucket, EveningBucket.later);
      expect(insight.count, 3);
      expect(insight.of, 5);
      expect(insight.suggestedReminderMinutes, 22 * 60);
      expect(insight.signature, 'later:3/5');
    });

    test('gelijkspel tussen avonddelen: geen inzicht', () {
      final p = analytics([
        rec(DateTime(2026, 11, 16, 21), 10, early: true),
        rec(DateTime(2026, 11, 15, 21), 10, early: true),
        rec(DateTime(2026, 11, 14, 23), 10, early: true),
        rec(DateTime(2026, 11, 13, 23), 10, early: true),
        rec(DateTime(2026, 11, 12, 21), 30),
      ]).patterns();
      expect(p.insight, isNull);
    });

    test('alleen het late deel krijgt een voorgestelde herinnering', () {
      final p = analytics([
        for (var i = 0; i < 5; i++)
          rec(DateTime(2026, 11, 16 - i, 21, 10), 10, early: true),
      ]).patterns();
      expect(p.insight!.bucket, EveningBucket.firstPart);
      expect(p.insight!.suggestedReminderMinutes, isNull);
    });

    test('weekdagen volgen de eerste dag van de week', () {
      final records = [
        rec(DateTime(2026, 11, 16, 21), 30), // ma
        rec(DateTime(2026, 11, 9, 21), 30, early: true), // ma
        rec(DateTime(2026, 11, 15, 21), 30), // zo
        rec(DateTime(2026, 11, 14, 21), 30), // za
        rec(DateTime(2026, 11, 13, 21), 30), // vr
      ];
      final monday = analytics(records).patterns().weekdays;
      expect(monday.map((d) => d.weekday), [1, 2, 3, 4, 5, 6, 7]);
      expect((monday[0].completed, monday[0].total), (1, 2));
      expect((monday[6].completed, monday[6].total), (1, 1));

      final sunday =
          analytics(records, weekStart: DateTime.sunday).patterns().weekdays;
      expect(sunday.map((d) => d.weekday), [7, 1, 2, 3, 4, 5, 6]);
    });

    test('weekend tegenover doordeweeks, pas met genoeg momenten aan beide '
        'kanten', () {
      final weekend = [
        for (final d in [14, 15, 7, 8, 1]) // za/zo
          rec(DateTime(2026, 11, d, 21), 30, early: d != 14),
      ];
      final weekdays = [
        for (final d in [16, 17, 18, 10, 11])
          rec(DateTime(2026, 11, d, 9), 30),
      ];
      final note = analytics([...weekend, ...weekdays]).patterns().weekend!;
      expect(note.harder, isTrue);
      expect(note.completed, 1);
      expect(note.total, 5);

      expect(
        analytics([...weekend, ...weekdays.take(4)]).patterns().weekend,
        isNull,
      );
    });
  });

  group('vergelijken', () {
    test('met vorige week', () {
      final c = analytics([
        rec(DateTime(2026, 11, 9, 21), 30),
        rec(DateTime(2026, 11, 10, 21), 30, early: true),
        rec(DateTime(2026, 11, 16, 21), 45),
        rec(DateTime(2026, 11, 17, 21), 20),
      ]).compare(0, ComparePeriod.lastWeek);
      expect((c.completed.current, c.completed.previous), (2, 1));
      expect(c.completed.change, 1);
      expect(c.protectedMinutes.change, 5);
      expect(c.endedEarly.change, -1);
      expect(c.hasProtectedTime, isTrue);
    });

    test('vier weken tegenover de vier weken daarvoor', () {
      final c = analytics([
        rec(DateTime(2026, 11, 16, 21), 30), // deze week
        rec(DateTime(2026, 10, 26, 21), 30), // 3 weken terug: telt nog
        rec(DateTime(2026, 10, 25, 21), 30), // 4 weken terug: vorige periode
        rec(DateTime(2026, 9, 28, 21), 30), // 7 weken terug: vorige periode
        rec(DateTime(2026, 9, 27, 21), 30), // 8 weken terug: valt erbuiten
      ]).compare(0, ComparePeriod.last4Weeks);
      expect((c.completed.current, c.completed.previous), (2, 2));
    });

    test('voor een eerdere week', () {
      final c = analytics([
        rec(DateTime(2026, 11, 2, 21), 30),
        rec(DateTime(2026, 11, 9, 21), 30),
        rec(DateTime(2026, 11, 10, 21), 30),
      ]).compare(1, ComparePeriod.lastWeek);
      expect((c.completed.current, c.completed.previous), (2, 1));
    });

    test('zonder blokkade: sessietijd in plaats van beschermde tijd', () {
      final c = analytics([
        rec(DateTime(2026, 11, 16, 21), 30, protected: false),
      ]).compare(0, ComparePeriod.lastWeek);
      expect(c.hasProtectedTime, isFalse);
      expect(c.sessionMinutes.current, 30);
    });
  });
}
