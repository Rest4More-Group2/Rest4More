
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/moments/moment_blocking.dart';
import 'package:rest4more/data/moments/moment_profiles.dart';
import 'package:rest4more/providers/database_providers.dart';
import 'package:rest4more/providers/repository_providers.dart';

import '../data/test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/blocking');
  late List<MethodCall> calls;
  late MomentProfileService service;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    final db = memoryDb();
    addTearDown(db.close);
    final container =
        ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);
    service = container.read(momentProfileServiceProvider);
  });

  test('Android: Reading zet alleen de apps van Reading', () async {
    await service.saveAndroidPackages(MomentKind.focus, {'focus.app'});
    await service.saveAndroidPackages(MomentKind.reading, {'read.app'});
    await MomentBlocking(service, channel: channel, isAndroid: true, isIos: false)
        .setBlocking(MomentKind.reading, true);
    expect(calls.map((c) => c.method), ['setBlockedPackages', 'setBlocking']);
    expect(calls.first.arguments['blockedPackages'], ['read.app']);
  });

  test('iOS: de selectie van het moment gaat mee, niet die van een ander',
      () async {
    await service.saveIosSelection(MomentKind.focus, Uint8List.fromList([1]));
    await service.saveIosSelection(MomentKind.reading, Uint8List.fromList([2]));
    await MomentBlocking(service, channel: channel, isAndroid: false, isIos: true)
        .setBlocking(MomentKind.reading, true);
    final args = calls.single.arguments as Map;
    expect(args['selection'], [2]);
    expect(args['momentSelection'], isTrue);
  });

  test('iOS: een moment zonder keuze valt niet terug op een andere', () async {
    await service.saveIosSelection(MomentKind.focus, Uint8List.fromList([1]));
    await MomentBlocking(service, channel: channel, isAndroid: false, isIos: true)
        .setBlocking(MomentKind.reading, true);
    final args = calls.single.arguments as Map;
    expect(args['selection'], isNull);
    expect(args['momentSelection'], isTrue);
  });

  test('uitzetten of zonder moment verandert niets aan de keuze', () async {
    final blocking =
        MomentBlocking(service, channel: channel, isAndroid: true, isIos: false);
    await blocking.setBlocking(MomentKind.reading, false);
    await blocking.setBlocking(null, true);
    expect(calls.map((c) => c.method), ['setBlocking', 'setBlocking']);
  });
}
