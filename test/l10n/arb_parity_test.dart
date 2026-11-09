import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> _keys(String path) => (jsonDecode(File(path).readAsStringSync())
        as Map<String, dynamic>)
    .keys
    .where((k) => !k.startsWith('@'))
    .toSet();

void main() {
  test('het Nederlands heeft precies dezelfde teksten als het Engels', () {
    final en = _keys('lib/l10n/app_en.arb');
    final nl = _keys('lib/l10n/app_nl.arb');
    expect(en.difference(nl), isEmpty, reason: 'ontbreekt in app_nl.arb');
    expect(nl.difference(en), isEmpty, reason: 'staat niet in app_en.arb');
  });
}
