import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/intake/intake_service.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/screens/app_root.dart';

import '../data/test_support.dart';
import 'onboarding_test_support.dart';

void main() {
  screenTest('"Not yet" laat dezelfde stap staan', (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    final intake = IntakeService(ProfileRepository(db));
    await intake.saveGoal(1);
    await intake.saveObstacles([1]);
    await intake.complete(reminderEnabled: false);

    await pumpScreen(tester, const AppRoot(), db: db);
    await settle(tester);
    await tester.tap(find.text('Start today’s step'));
    await settle(tester);
    await tester.tap(find.text('Not yet'));
    await settle(tester);

    expect(find.text('DAY 1 OF 14'), findsOneWidget);
    final day1 = (await tester.runAsync(() => db.select(db.programmeDays).get()))!
        .firstWhere((d) => d.dayNumber == 1);
    expect(day1.status, DayStatus.opened, reason: 'wel gestart, niet af');
    expect(day1.completedAt, isNull);
  });
}
