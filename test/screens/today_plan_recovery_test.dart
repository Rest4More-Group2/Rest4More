import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/intake/intake_service.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/screens/app_root.dart';
import 'package:rest4more/screens/app_shell.dart';

import '../data/test_support.dart';
import 'onboarding_test_support.dart';

void main() {
  screenTest('opstarten met afgeronde onboarding maakt een ontbrekend plan alsnog',
      (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    final intake = IntakeService(ProfileRepository(db));
    await intake.saveGoal(2);
    await intake.saveObstacles([4]);
    await intake.complete(reminderEnabled: false);
    expect(await db.select(db.programmeEnrollments).get(), isEmpty);

    await pumpScreen(tester, const AppRoot(), db: db);
    await settle(tester);

    expect(find.byType(AppShell), findsOneWidget);
    expect(await db.select(db.programmeDays).get(), hasLength(14));
    expect(find.text('DAY 1 OF 14'), findsOneWidget);
  });
}
