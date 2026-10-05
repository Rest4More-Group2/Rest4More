import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/database/encrypted_database.dart';

const _keyA =
    '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff';
const _keyB =
    'ffeeddccbbaa99887766554433221100ffeeddccbbaa99887766554433221100';

void main() {
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('rfm_enc_test');
    file = File('${dir.path}/test.sqlite');
  });
  tearDown(() => dir.delete(recursive: true));

  Future<bool> isPlainSqlite(File f) async {
    final bytes = await f.openRead(0, 15).expand((b) => b).toList();
    return String.fromCharCodes(bytes) == 'SQLite format 3';
  }

  Future<AppDatabase> open(String key) async =>
      AppDatabase(await openEncryptedFile(file, key));

  Future<void> addRoutine(AppDatabase db, String name) =>
      db.into(db.routines).insert(RoutinesCompanion.insert(
            mode: 'focus',
            name: name,
            updatedAt: DateTime.utc(2026, 3, 2),
          ));

  test('een nieuwe database is versleuteld en blijft leesbaar met de sleutel',
      () async {
    var db = await open(_keyA);
    await addRoutine(db, 'geheim-woord');
    await db.close();

    expect(await isPlainSqlite(file), isFalse);
    expect(String.fromCharCodes(await file.readAsBytes()),
        isNot(contains('geheim-woord')));

    db = await open(_keyA);
    addTearDown(db.close);
    expect((await db.select(db.routines).getSingle()).name, 'geheim-woord');
  });

  test('een bestaande niet-versleutelde database wordt ter plekke versleuteld',
      () async {
    final plain = AppDatabase(NativeDatabase(file));
    await addRoutine(plain, 'oude-data');
    await plain.close();
    expect(await isPlainSqlite(file), isTrue);

    final db = await open(_keyA);
    addTearDown(db.close);
    expect((await db.select(db.routines).getSingle()).name, 'oude-data');
    await db.close();

    expect(await isPlainSqlite(file), isFalse);
    expect(String.fromCharCodes(await file.readAsBytes()),
        isNot(contains('oude-data')));
  });

  test('zonder sleutel is het bestand onleesbaar', () async {
    final db = await open(_keyA);
    await addRoutine(db, 'x');
    await db.close();

    final raw = AppDatabase(NativeDatabase(file));
    addTearDown(raw.close);
    await expectLater(raw.select(raw.routines).get(), throwsA(anything));
  });

  test('verkeerde sleutel: het bestand wordt opnieuw aangemaakt', () async {
    var db = await open(_keyA);
    await addRoutine(db, 'verloren');
    await db.close();

    db = await open(_keyB);
    addTearDown(db.close);
    expect(await db.select(db.routines).get(), isEmpty);
    await addRoutine(db, 'nieuw');
    await db.close();

    db = await open(_keyB);
    expect((await db.select(db.routines).getSingle()).name, 'nieuw');
    addTearDown(db.close);
  });

  test('sleutel is 64 hex-tekens en wordt hergebruikt', () async {
    final store = _MemoryKeyStore();
    final a = await store.loadOrCreateHexKey();
    expect(a, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(await store.loadOrCreateHexKey(), a);
  });
}

class _MemoryKeyStore implements DatabaseKeyStore {
  String? _key;

  @override
  Future<String> loadOrCreateHexKey() async =>
      _key ??= List.filled(64, 'a').join();
}
