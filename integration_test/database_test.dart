import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
    await _clear(db);

    await ProfileRepository(db).upsert(const ProfileDraft(displayName: 'Sam'));
    final session = await FocusSessionRepository(db).start(
      mode: 'focus',
      source: SessionSource.manual,
      platform: SessionPlatform.android,
    );
    await db.close();

    db = AppDatabase();
    addTearDown(() async {
      await _clear(db);
      await db.close();
    });

    expect((await ProfileRepository(db).get()).displayName, 'Sam');
    expect(await db.select(db.profiles).get(), hasLength(1));
    final open = await FocusSessionRepository(db).findOpen();
    expect(open?.id, session.id);
    expect(open?.state, SessionState.selecting);

    // Het bestand op het toestel is versleuteld, niet gewoon SQLite.
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'restformore.sqlite'));
    expect(await file.exists(), isTrue);
    final header = await file.openRead(0, 15).expand((b) => b).toList();
    expect(String.fromCharCodes(header), isNot('SQLite format 3'));
  });
}

/// Maakt de tabellen leeg die de test gebruikt, kinderen eerst, zodat data van
/// eerdere runs (zoals voorbeelddata) geen verwijzingen laat staan.
Future<void> _clear(AppDatabase db) async {
  for (final table in [
    'local_notifications',
    'programme_days',
    'programme_enrollments',
    'focus_sessions',
    'consent_records',
    'profiles',
  ]) {
    await db.customStatement('DELETE FROM $table');
  }
}
