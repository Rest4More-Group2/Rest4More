import 'package:drift/drift.dart' show UpdateKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/intake/intake_service.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/screens/app_root.dart';

import '../data/test_support.dart';
import 'onboarding_test_support.dart';

void main() {
  screenTest('de volgende dag is de volgende stap weer beschikbaar',
      (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    final intake = IntakeService(ProfileRepository(db));
    await intake.saveGoal(0);
    await intake.saveObstacles([0]);
    await intake.complete(reminderEnabled: false);

    await pumpScreen(tester, const AppRoot(), db: db);
    await settle(tester);
    await tester.tap(find.text('Start today’s step'));
    await settle(tester);
    await tester.tap(find.text('Mark as done'));
    await settle(tester);
    expect(find.text('Today’s step is done'), findsOneWidget);

    // Gisteren afgerond in plaats van vandaag: een nieuwe dag is aangebroken.
    final yesterday =
        DateTime.now().subtract(const Duration(days: 1)).toUtc().toIso8601String();
    await tester.runAsync(() => db.customUpdate(
          "UPDATE programme_days SET completed_at = '$yesterday' "
          "WHERE day_number = 1",
          updates: {db.programmeDays},
          updateKind: UpdateKind.update,
        ));
    await pumpScreen(tester, const AppRoot(), db: db);
    await settle(tester);
    expect(find.text('DAY 2 OF 14'), findsOneWidget);
    expect(find.text('Start today’s step'), findsOneWidget);
  });
}
