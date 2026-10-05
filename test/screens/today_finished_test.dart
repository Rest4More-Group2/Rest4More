import 'package:drift/drift.dart' show UpdateKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/intake/intake_service.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/screens/app_root.dart';

import '../data/test_support.dart';
import 'onboarding_test_support.dart';

void main() {
  screenTest('alle stappen gedaan toont dat het eigen ritme doorgaat',
      (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    final intake = IntakeService(ProfileRepository(db));
    await intake.saveGoal(2);
    await intake.saveObstacles([2]);
    await intake.complete(reminderEnabled: false);

    await pumpScreen(tester, const AppRoot(), db: db);
    await settle(tester);
    // Met `customUpdate`, zodat lopende stromen de wijziging zien.
    await tester.runAsync(() => db.customUpdate(
          "UPDATE programme_days SET status = 'completed'",
          updates: {db.programmeDays},
          updateKind: UpdateKind.update,
        ));

    await pumpScreen(tester, const AppRoot(), db: db);
    await settle(tester);
    expect(find.text('All 14 steps are done'), findsOneWidget);
    expect(find.textContaining('Your own routine continues'), findsOneWidget);
    expect(find.text('Start today’s step'), findsNothing);
  });
}
