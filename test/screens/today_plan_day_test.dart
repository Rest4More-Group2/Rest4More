import 'package:drift/drift.dart' show UpdateKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/intake/intake_service.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';
import 'package:rest4more/screens/app_root.dart';

import '../data/test_support.dart';
import 'onboarding_test_support.dart';

void main() {
  screenTest('Today toont de dag van vandaag uit de database', (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    final intake = IntakeService(ProfileRepository(db));
    await intake.saveGoal(0);
    await intake.saveObstacles([0]);
    await intake.complete(reminderEnabled: false);
    // Begin 4 dagen geleden: vandaag is dag 5.
    final start = DateTime.now().subtract(const Duration(days: 4));
    await db.customStatement('SELECT 1');
    await pumpScreen(tester, const AppRoot(), db: db);
    await settle(tester);
    for (var i = 1; i <= 14; i++) {
      final d = DateTime(start.year, start.month, start.day + i - 1);
      final text =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      // Met `customUpdate`, zodat lopende stromen de wijziging zien.
      await db.customUpdate(
        "UPDATE programme_days SET scheduled_for = '$text' WHERE day_number = $i",
        updates: {db.programmeDays},
        updateKind: UpdateKind.update,
      );
    }
    // Opnieuw openen: nu moet dag 5 de huidige zijn.
    await pumpScreen(tester, const AppRoot(), db: db);
    await settle(tester);
    expect(find.text('DAY 5 OF 14'), findsOneWidget);
    expect(find.text('Protect a starting moment'), findsOneWidget);
  });
}
