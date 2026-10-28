import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/moments/moment_schedule.dart';

void main() {
  test('telt terug vanaf een bedtijd voor middernacht', () {
    final t = eveningTimes(
      eveningDate: DateTime(2026, 10, 12),
      bedtimeMinutes: 22 * 60 + 30,
      windDownLeadMinutes: 45,
      blockLeadMinutes: 30,
      graceMinutes: 10,
    );
    expect(t.bedtime, DateTime(2026, 10, 12, 22, 30));
    expect(t.blockStart, DateTime(2026, 10, 12, 22, 0));
    expect(t.windDown, DateTime(2026, 10, 12, 21, 15));
    expect(t.reminderIfNotStarted, DateTime(2026, 10, 12, 22, 10));
  });

  test('bedtijd na middernacht valt op de volgende dag, het blok niet', () {
    final t = eveningTimes(
      eveningDate: DateTime(2026, 10, 30),
      bedtimeMinutes: 30, // 00:30
      windDownLeadMinutes: 45,
      blockLeadMinutes: 60,
      graceMinutes: 10,
    );
    expect(t.bedtime, DateTime(2026, 10, 31, 0, 30));
    expect(t.blockStart, DateTime(2026, 10, 30, 23, 30));
    expect(t.windDown, DateTime(2026, 10, 30, 22, 45));
  });

  test('dagwisseling aan het einde van de maand en het jaar', () {
    final t = eveningTimes(
      eveningDate: DateTime(2026, 12, 31),
      bedtimeMinutes: 60,
      windDownLeadMinutes: 30,
      blockLeadMinutes: 30,
      graceMinutes: 5,
    );
    expect(t.bedtime, DateTime(2027, 1, 1, 1, 0));
    expect(t.blockStart, DateTime(2027, 1, 1, 0, 30));
    expect(t.windDown, DateTime(2027, 1, 1, 0, 0));
  });

  test('grens van de nachtgrens', () {
    expect(isAfterMidnight(0), isTrue);
    expect(isAfterMidnight(5 * 60 + 59), isTrue);
    expect(isAfterMidnight(6 * 60), isFalse);
    expect(isAfterMidnight(23 * 60 + 59), isFalse);
  });

  test('ochtendblok eindigt na het aantal minuten', () {
    final w = morningWindow(
      morningDate: DateTime(2026, 10, 12),
      wakeMinutes: 6 * 60 + 45,
      blockMinutes: 45,
    );
    expect(w.start, DateTime(2026, 10, 12, 6, 45));
    expect(w.end, DateTime(2026, 10, 12, 7, 30));
  });

  test('formatMinutes vult nullen aan', () {
    expect(formatMinutes(5), '00:05');
    expect(formatMinutes(22 * 60 + 30), '22:30');
  });
}
