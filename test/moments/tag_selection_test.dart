
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/moments/moment_blocking.dart';
import 'package:rest4more/data/moments/moment_profiles.dart';
import 'package:rest4more/data/moments/tag_selection_sync.dart';
import 'package:rest4more/providers/database_providers.dart';
import 'package:rest4more/providers/repository_providers.dart';

import '../data/test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/tag');
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

  TagSelectionSync sync({required bool android}) => TagSelectionSync(service,
      channel: channel, isAndroid: android, isIos: !android);

  test('Tag heeft een eigen profiel, los van Focus', () async {
    await service.saveAndroidPackages(MomentKind.focus, {'focus.app'});
    await service.saveAndroidPackages(MomentKind.tag, {'tag.app'});
    final focus = await service.ensure(MomentKind.focus);
    final tag = await service.ensure(MomentKind.tag);
    expect(tag.id, isNot(focus.id));
    expect(tag.name, 'Tag');
    expect(MomentProfileService.androidPackages(tag), {'tag.app'});
  });

  test('Android: alleen de apps van Tag gaan naar het toestel', () async {
    await service.saveAndroidPackages(MomentKind.focus, {'focus.app'});
    await service.saveAndroidPackages(MomentKind.tag, {'b.app', 'a.app'});
    await sync(android: true).mirror();
    expect(calls.single.method, 'setTagSelection');
    expect((calls.single.arguments['packages'] as List).toSet(),
        {'a.app', 'b.app'});
  });

  test('Android: zonder keuze wordt de kopie leeg', () async {
    await service.saveAndroidPackages(MomentKind.focus, {'focus.app'});
    await sync(android: true).mirror();
    expect(calls.single.arguments['packages'], isEmpty);
  });

  test('iOS: de selectie van Tag gaat mee, niet die van Focus', () async {
    await service.saveIosSelection(MomentKind.focus, Uint8List.fromList([1]));
    await service.saveIosSelection(MomentKind.tag, Uint8List.fromList([7]));
    await sync(android: false).mirror();
    expect(calls.single.arguments['selection'], [7]);
  });

  test('iOS: zonder keuze van Tag gaat er geen selectie mee', () async {
    await service.saveIosSelection(MomentKind.focus, Uint8List.fromList([1]));
    await sync(android: false).mirror();
    expect(calls.single.arguments['selection'], isNull);
  });

  test('blokkeren voor Tag gebruikt de apps van Tag', () async {
    await service.saveAndroidPackages(MomentKind.focus, {'focus.app'});
    await service.saveAndroidPackages(MomentKind.tag, {'tag.app'});
    await MomentBlocking(service,
            channel: channel, isAndroid: true, isIos: false)
        .setBlocking(MomentKind.tag, true);
    expect(calls.first.method, 'setBlockedPackages');
    expect(calls.first.arguments['blockedPackages'], ['tag.app']);
  });
}
