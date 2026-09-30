import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/app_database.dart';

void main() {
  test('schema en gedeeltelijke unieke indexen worden aangemaakt', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final rows = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
        .get();
    final names = rows.map((r) => r.read<String>('name')).toSet();
    expect(names, containsAll(['one_open_session', 'one_live_enrollment']));
    final version = await db.customSelect('select sqlite_version() v').getSingle();
    // ignore: avoid_print
    print('sqlite ${version.read<String>('v')}');
  });
}
