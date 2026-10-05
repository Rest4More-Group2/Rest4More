import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('het huidige schema komt overeen met de dump van de laatste versie',
      () async {
    final schema = await verifier.schemaAt(2);
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);
  });

  test('migratie van v1 naar v2 voegt consent_records toe en houdt data',
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
    await verifier.migrateAndValidate(db, 2);
    expect((await db.select(db.routines).getSingle()).id, 'r1');
    expect(await db.select(db.consentRecords).get(), isEmpty);
  });
}
