import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/converters.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/moments/moment_profiles.dart';
import 'package:rest4more/providers/database_providers.dart';
import 'package:rest4more/providers/repository_providers.dart';
import 'package:rest4more/screens/moment_app_picker_screen.dart';

import '../data/test_support.dart';
import 'onboarding_test_support.dart';

Future<List<PickableApp>> _fakeApps() async => const [
      PickableApp(name: 'Instagram', id: 'com.instagram'),
      PickableApp(name: 'Kindle', id: 'com.kindle'),
      PickableApp(name: 'Mail', id: 'com.mail'),
    ];

void main() {
  test('elk moment krijgt zijn eigen profiel met eigen apps', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);
    final service = container.read(momentProfileServiceProvider);

    await service.saveAndroidPackages(MomentKind.focus, {'b', 'a'});
    await service.saveAndroidPackages(MomentKind.reading, {'c'});

    final focus = await service.ensure(MomentKind.focus);
    final reading = await service.ensure(MomentKind.reading);
    expect(focus.id, isNot(reading.id));
    expect(MomentProfileService.androidPackages(focus), {'a', 'b'});
    expect(MomentProfileService.androidPackages(reading), {'c'});
    // Nog eens opvragen maakt geen tweede profiel.
    expect((await service.ensure(MomentKind.focus)).id, focus.id);
    expect(await db.select(db.blockProfiles).get(), hasLength(2));
  });

  test('andere items blijven staan bij opslaan', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);
    final service = container.read(momentProfileServiceProvider);
    final profile = await service.ensure(MomentKind.evening);
    await container.read(blockProfileRepositoryProvider).setItems(profile.id, [
      const BlockItemData(kind: BlockItemKind.url, value: 'example.com'),
    ]);
    await service.saveAndroidPackages(MomentKind.evening, {'x'});
    final after = await service.ensure(MomentKind.evening);
    expect(after.items.map((i) => i.value), ['example.com', 'x']);
  });

  test('de iOS-selectie hoort bij het profiel van het moment', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);
    final service = container.read(momentProfileServiceProvider);
    expect(await service.iosSelection(MomentKind.morning), isNull);
    await service.saveIosSelection(
        MomentKind.morning, Uint8List.fromList([1, 2, 3]));
    expect(await service.iosSelection(MomentKind.morning), [1, 2, 3]);
    expect(await service.iosSelection(MomentKind.focus), isNull);
  });

  screenTest('de kiezer bewaart de keuze voor dat moment', (tester) async {
    final db = await pumpScreen(
        tester, const MomentAppPickerScreen(kind: MomentKind.reading, loadApps: _fakeApps));
    await settle(tester);
    await tester.tap(find.text('Kindle'));
    await tester.pump();
    expect(find.text('Save · 1 selected'), findsOneWidget);
    await tester.tap(find.textContaining('Save'));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    final profiles =
        await tester.runAsync(() => db.select(db.blockProfiles).get());
    expect(profiles!.single.name, 'Reading');
    expect(profiles.single.items.map((i) => i.value), ['com.kindle']);
  });

  screenTest('de kiezer toont wat al bewaard is', (tester) async {
    final db = memoryDb();
    addTearDown(db.close);
    final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    await tester.runAsync(() => container
        .read(momentProfileServiceProvider)
        .saveAndroidPackages(MomentKind.focus, {'com.mail'}));
    container.dispose();
    await pumpScreen(
      tester,
      const MomentAppPickerScreen(kind: MomentKind.focus, loadApps: _fakeApps),
      db: db,
    );
    await settle(tester);
    expect(find.text('Save · 1 selected'), findsOneWidget);
    final box = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'Mail'));
    expect(box.value, isTrue);
  });
}
