import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/intake/intake_service.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/screens/app_root.dart';

import '../data/test_support.dart';
import 'onboarding_test_support.dart';

void main() {
  screenTest('een stap starten en afronden schuift het plan door',
      (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    final intake = IntakeService(ProfileRepository(db));
    await intake.saveGoal(0);
    await intake.saveObstacles([0]);
    await intake.complete(reminderEnabled: false);

    await pumpScreen(tester, const AppRoot(), db: db);
    await settle(tester);
    expect(find.text('DAY 1 OF 14'), findsOneWidget);
    // De getoonde stap is aangeboden.
    var day1 = (await tester.runAsync(() => db.select(db.programmeDays).get()))!
        .firstWhere((d) => d.dayNumber == 1);
    expect(day1.status, DayStatus.offered);
    expect(day1.offeredAt, isNotNull);

    await tester.tap(find.text('Start today’s step'));
    await settle(tester);
    expect(find.text('Mark as done'), findsOneWidget);
    day1 = (await tester.runAsync(() => db.select(db.programmeDays).get()))!
        .firstWhere((d) => d.dayNumber == 1);
    expect(day1.status, DayStatus.opened);
    expect(day1.completedAt, isNull, reason: 'starten rondt niet af');

    await tester.tap(find.text('Mark as done'));
    await settle(tester);

    day1 = (await tester.runAsync(() => db.select(db.programmeDays).get()))!
        .firstWhere((d) => d.dayNumber == 1);
    expect(day1.status, DayStatus.completed);
    expect(day1.completedAt, isNotNull);
    expect(find.text('DAY 2 OF 14'), findsOneWidget);
    expect(find.text('Day 1 is done.'), findsOneWidget);
  });
}
