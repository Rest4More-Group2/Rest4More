import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v4.dart' as v4;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('het huidige schema komt overeen met de dump van de laatste versie',
      () async {
    final schema = await verifier.schemaAt(5);
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 5);
  });

  test('migratie van v1 naar de nieuwste versie houdt data en voegt tabellen toe',
      () async {
    final schema = await verifier.schemaAt(1);
    final oldDb = v1.DatabaseAtV1(schema.newConnection());
    await oldDb.customStatement(
      "INSERT INTO routines (id, mode, name, end_rule, days_mask, auto_start, "
      "enabled, updated_at, dirty) VALUES ('r1', 'focus', 'Avond', 'manual', 0, "
      "0, 1, '2026-03-02T00:00:00.000Z', 1)",
    );
    await oldDb.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 5);
    expect((await db.select(db.routines).getSingle()).id, 'r1');
    expect(await db.select(db.consentRecords).get(), isEmpty);
    expect(await db.select(db.syncCursors).get(), isEmpty);
  });

  test('migratie van v2 naar v3 voegt sync_cursors toe', () async {
    final schema = await verifier.schemaAt(2);
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 3);
    expect(await db.select(db.syncCursors).get(), isEmpty);
  });

  test('migratie van v4 naar v5 houdt sessies en voegt de lokale redenen toe',
      () async {
    final schema = await verifier.schemaAt(4);
    final oldDb = v4.DatabaseAtV4(schema.newConnection());
    await oldDb.customStatement(
      "INSERT INTO focus_sessions (id, mode, source, platform, state, "
      "started_at, local_date, updated_at, dirty, events) VALUES ('s1', "
      "'focus', 'manual', 'android', 'completed', '2026-03-02T10:00:00.000Z', "
      "'2026-03-02', '2026-03-02T10:00:00.000Z', 1, '[]')",
    );
    await oldDb.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 5);
    expect((await db.select(db.focusSessions).getSingle()).id, 's1');
    expect(await db.select(db.sessionEndReasons).get(), isEmpty);
  });
}
