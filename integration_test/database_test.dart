import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/repositories/focus_session_repository.dart';
import 'package:rest4more/data/repositories/profile_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('gegevens overleven het sluiten en heropenen van de database',
      (tester) async {
    // Een eerdere run kan data hebben achtergelaten in het echte bestand.
    var db = AppDatabase();
    await db.delete(db.focusSessions).go();
    await db.delete(db.profiles).go();

    await ProfileRepository(db).upsert(const ProfileDraft(displayName: 'Sam'));
    final session = await FocusSessionRepository(db).start(
      mode: 'focus',
      source: SessionSource.manual,
      platform: SessionPlatform.android,
    );
    await db.close();

    db = AppDatabase();
    addTearDown(() async {
      await db.delete(db.focusSessions).go();
      await db.delete(db.profiles).go();
      await db.close();
    });

    expect((await ProfileRepository(db).get()).displayName, 'Sam');
    expect(await db.select(db.profiles).get(), hasLength(1));
    final open = await FocusSessionRepository(db).findOpen();
    expect(open?.id, session.id);
    expect(open?.state, SessionState.selecting);
  });
}
