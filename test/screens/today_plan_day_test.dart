import 'package:drift/drift.dart' show UpdateKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/intake/intake_service.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/data/repositories/programme_repository.dart';
import 'package:rest4more/screens/app_root.dart';

import '../data/test_support.dart';
import 'onboarding_test_support.dart';

void main() {
  screenTest('na dagen weg gaat de gebruiker verder waar hij was gebleven',
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

    // Twee stappen gedaan, daarna een lange pauze: de datums liggen ver terug.
    final programme = ProgrammeRepository(db);
    final days = await tester.runAsync(() => db.select(db.programmeDays).get());
    for (final n in [1, 2]) {
      await tester.runAsync(() => programme
          .markCompleted(days!.firstWhere((d) => d.dayNumber == n).id));
    }
    // Ze zijn dagen geleden afgerond, niet vandaag.
    await tester.runAsync(() => db.customUpdate(
          "UPDATE programme_days SET completed_at = '2020-01-02T10:00:00.000Z' "
          "WHERE status = 'completed'",
          updates: {db.programmeDays},
          updateKind: UpdateKind.update,
        ));
    await tester.runAsync(() => db.customUpdate(
          "UPDATE programme_days SET scheduled_for = '2020-01-01'",
          updates: {db.programmeDays},
          updateKind: UpdateKind.update,
        ));

    // Opnieuw openen.
    await pumpScreen(tester, const AppRoot(), db: db);
    await settle(tester);
    expect(find.text('DAY 3 OF 14'), findsOneWidget);
    expect(find.text('Fewer interruptions'), findsOneWidget);
  });
}
