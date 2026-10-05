import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/converters.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/database/local_types.dart';

void main() {
  group('jsonb', () {
    test('routine steps: rondreis en slechte items', () {
      const conv = RoutineStepsConverter();
      const steps = [
        RoutineStepData(title: 'Lezen', durationMin: 10),
        RoutineStepData(title: 'Stilte'),
      ];
      expect(conv.fromSql(conv.toSql(steps)), steps);
      expect(
        conv.fromSql('[{"title":"Ok","duration_min":5},42,{"x":1},null]'),
        [const RoutineStepData(title: 'Ok', durationMin: 5)],
      );
      expect(conv.fromSql('geen json'), isEmpty);
      expect(conv.fromSql('{"a":1}'), isEmpty);
    });

    test('block items: rondreis, onbekende waarden en slechte items', () {
      const conv = BlockItemsConverter();
      const items = [
        BlockItemData(kind: BlockItemKind.url, value: 'example.com'),
        BlockItemData(
          kind: BlockItemKind.androidPackage,
          value: 'com.x',
          rule: BlockItemRule.allow,
        ),
      ];
      expect(conv.fromSql(conv.toSql(items)), items);
      final tolerant = conv.fromSql(
        '[{"kind":"nieuw","value":"a","rule":"raar"},{"value":5},"x"]',
      );
      expect(tolerant, [
        const BlockItemData(
          kind: BlockItemKind.unknown,
          value: 'a',
          rule: BlockItemRule.unknown,
        ),
      ]);
    });

    test('sessie-events: rondreis en slechte items', () {
      const conv = SessionEventsConverter();
      final events = [
        SessionEventData(
          at: DateTime.utc(2026, 3, 2, 9, 30, 15, 123),
          event: SessionEventType.transition,
          fromState: SessionState.selecting,
          toState: SessionState.awaitingScan,
          errorCode: 'e1',
        ),
      ];
      final back = conv.fromSql(conv.toSql(events));
      expect(back, hasLength(1));
      expect(back.first.at, events.first.at);
      expect(back.first.event, SessionEventType.transition);
      expect(back.first.fromState, SessionState.selecting);
      expect(back.first.toState, SessionState.awaitingScan);
      expect(back.first.errorCode, 'e1');

      final tolerant = conv.fromSql(
        '[{"event":"transition"},{"at":"kapot"},'
        '{"at":"2026-03-02T09:00:00Z","event":"nieuw","to_state":"weg"}]',
      );
      expect(tolerant, hasLength(1));
      expect(tolerant.first.event, SessionEventType.unknown);
      expect(tolerant.first.toState, SessionState.unknown);
      expect(tolerant.first.fromState, isNull);
    });

    test('ongetypeerde map: rondreis en slechte invoer', () {
      const conv = JsonMapConverter();
      final map = {'a': 1, 'b': [1, 2]};
      expect(conv.fromSql(conv.toSql(map)), map);
      expect(conv.fromSql('kapot'), isEmpty);
      expect(conv.fromSql('[1]'), isEmpty);
    });
  });

  group('enums', () {
    void check<T extends DbEnum>(List<T> values, T fallback) {
      final conv = DbEnumConverter<T>(values, fallback);
      expect(conv.fromSql('bestaat_niet'), fallback, reason: '$T');
      expect(conv.fromSql(''), fallback, reason: '$T');
      for (final v in values) {
        expect(conv.fromSql(conv.toSql(v)), v, reason: '$T ${v.id}');
      }
    }

    test('elke enum valt terug op unknown zonder te gooien', () {
      check(AgeBand.values, AgeBand.unknown);
      check(PrimaryGoal.values, PrimaryGoal.unknown);
      check(Obstacle.values, Obstacle.unknown);
      check(Rhythm.values, Rhythm.unknown);
      check(StepSize.values, StepSize.unknown);
      check(PreferredActivity.values, PreferredActivity.unknown);
      check(RoutineEndRule.values, RoutineEndRule.unknown);
      check(BlockContext.values, BlockContext.unknown);
      check(BlockItemKind.values, BlockItemKind.unknown);
      check(BlockItemRule.values, BlockItemRule.unknown);
      check(AccessoryKind.values, AccessoryKind.unknown);
      check(AccessoryStatus.values, AccessoryStatus.unknown);
      check(SessionSource.values, SessionSource.unknown);
      check(SessionPlatform.values, SessionPlatform.unknown);
      check(SessionState.values, SessionState.unknown);
      check(SessionOutcome.values, SessionOutcome.unknown);
      check(SessionFeeling.values, SessionFeeling.unknown);
      check(SessionEventType.values, SessionEventType.unknown);
      check(EnrollmentStatus.values, EnrollmentStatus.unknown);
      check(ProgrammeDirection.values, ProgrammeDirection.unknown);
      check(DayStatus.values, DayStatus.unknown);
      check(DaySize.values, DaySize.unknown);
      check(DayFit.values, DayFit.unknown);
      check(DayBlocker.values, DayBlocker.unknown);
      check(DayProtected.values, DayProtected.unknown);
      check(NotificationKind.values, NotificationKind.unknown);
      check(NotificationStatus.values, NotificationStatus.unknown);
      check(EntitlementSource.values, EntitlementSource.unknown);
      check(EntitlementStatus.values, EntitlementStatus.unknown);
    });

    test('opslagtekst is exact zoals in het schema', () {
      expect(AgeBand.age16To17.id, '16_17');
      expect(Obstacle.noRoutine.id, 'no_routine');
      expect(SessionState.awaitingScan.id, 'awaiting_scan');
      expect(SessionOutcome.emergencyRelease.id, 'emergency_release');
      expect(EntitlementSource.cardPurchase.id, 'card_purchase');
      expect(SessionSource.schedule.id, 'schedule');
    });
  });

  group('WeekdayMask en LocalDate', () {
    test('rondreis met alle combinaties van weekdagen', () {
      for (var mask = 0; mask < 128; mask++) {
        final days = WeekdayMask(mask).toWeekdays();
        expect(WeekdayMask.fromWeekdays(days).value, mask);
      }
    });

    test('bitwaarden en ongeldige dagen', () {
      expect(WeekdayMask.fromWeekdays({1}).value, 1);
      expect(WeekdayMask.fromWeekdays({2}).value, 2);
      expect(WeekdayMask.fromWeekdays({3}).value, 4);
      expect(WeekdayMask.fromWeekdays({7}).value, 64);
      expect(WeekdayMask.fromWeekdays({0, 8, -1}).value, 0);
      expect(WeekdayMask.fromWeekdays({1, 2, 3, 4, 5, 6, 7}), WeekdayMask.everyDay);
      expect(WeekdayMask(5).toWeekdays(), {1, 3});
    });

    test('LocalDate formatteert en leest', () {
      expect(LocalDate.format(DateTime(2026, 3, 2, 23, 50)), '2026-03-02');
      expect(LocalDate.parse('2026-03-02'), DateTime(2026, 3, 2));
      expect(LocalDate.parse('2026-02-30'), isNull);
      expect(LocalDate.parse('kapot'), isNull);
      expect(LocalDate.parse(null), isNull);
    });
  });
}
