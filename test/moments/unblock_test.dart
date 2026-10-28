import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/database/converters.dart';
import 'package:rest4more/data/database/enums.dart';
import 'package:rest4more/data/moments/moment_blocking.dart';
import 'package:rest4more/data/moments/moment_profiles.dart';
import 'package:rest4more/data/moments/session_runner.dart';
import 'package:rest4more/data/moments/unblock_service.dart';
import 'package:rest4more/data/repositories/focus_session_repository.dart';
import 'package:rest4more/providers/database_providers.dart';
import 'package:rest4more/providers/repository_providers.dart';
import 'package:rest4more/screens/moment_app_picker_screen.dart';

import '../data/test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/unblock');
  late List<MethodCall> calls;
  List<String> blocked = [];

  setUp(() {
    calls = [];
    blocked = ['com.insta', 'com.unknown'];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'getBlockedPackages') return blocked;
      if (call.method == 'takePendingUnblock') return 'com.insta';
      return null;
    });
  });

  UnblockService service({bool android = true, DateTime? now}) =>
      UnblockService(
        channel: channel,
        isAndroid: android,
        isIos: !android,
        now: () => now ?? DateTime(2026, 10, 12, 14, 0),
      );

  test('de keuzes zijn 1, 5, 10 en 15 minuten met een pauze van 5 seconden',
      () {
    expect(UnblockPolicy.minutes, [1, 5, 10, 15]);
    expect(UnblockPolicy.pause, const Duration(seconds: 5));
  });

  test('vrijgeven geeft het eindtijdstip terug en stuurt app en minuten mee',
      () async {
    final until = await service().grant(package: 'com.insta', minutes: 5);
    expect(until, DateTime(2026, 10, 12, 14, 5));
    expect(calls.single.method, 'grantUnblock');
    expect(calls.single.arguments, {'package': 'com.insta', 'minutes': 5});
  });

  test('een niet toegestane duur wordt geweigerd en bereikt het toestel niet',
      () async {
    for (final bad in [0, 2, 20, 60, -5]) {
      await expectLater(
        service().grant(package: 'com.insta', minutes: bad),
        throwsArgumentError,
      );
    }
    expect(calls, isEmpty);
  });

  test('iOS pauzeert de hele blokkade: geen pakketnaam', () async {
    expect(service(android: false).choosesApp, isFalse);
    await service(android: false).grant(minutes: 10);
    expect(calls.single.arguments, {'minutes': 10});
  });

  test('geblokkeerde apps krijgen hun naam; onbekende vallen terug op de id',
      () async {
    final apps = await service().blockedApps(() async => const [
          PickableApp(name: 'Instagram', id: 'com.insta'),
          PickableApp(name: 'Mail', id: 'com.mail'),
        ]);
    expect(apps.map((a) => a.name).toList(), ['com.unknown', 'Instagram']);
    expect(apps.map((a) => a.id), isNot(contains('com.mail')),
        reason: 'niet geblokkeerd, dus niet in de lijst');
  });

  test('het verzoek van het blokkeerscherm geldt alleen op Android', () async {
    expect(await service().takePendingRequest(), 'com.insta');
    calls.clear();
    expect(await service(android: false).takePendingRequest(), isNull);
    expect(calls, isEmpty);
  });

  test('iOS zet de blokkade pas terug op iOS', () async {
    await service().reapplyIfExpired();
    expect(calls, isEmpty);
    await service(android: false).reapplyIfExpired();
    expect(calls.single.method, 'reapplyIfExpired');
  });

  test('vrijgeven staat in het logboek en laat de sessie doorlopen', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final container =
        ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);
    final runner = SessionRunner(
      FocusSessionRepository(db),
      MomentBlocking(container.read(momentProfileServiceProvider),
          channel: channel, isAndroid: true, isIos: false),
      platform: SessionPlatform.android,
    );
    final running = await runner.start(kind: MomentKind.focus, minutes: 25);

    await runner.logUnblock(running.id, 10);

    final row = (await db.select(db.focusSessions).get()).single;
    expect(row.state, SessionState.active);
    final unblock =
        row.events.where((e) => e.event == SessionEventType.unblockGranted);
    expect(unblock.single.minutes, 10);
    expect(row.endedAt, isNull);
  });

  test('een gebeurtenis zonder minuten schrijft geen minuten weg', () {
    final event = SessionEventData(
      at: DateTime.utc(2026),
      event: SessionEventType.transition,
    );
    expect(event.toJson().containsKey('minutes'), isFalse);
    final back = SessionEventData.tryFromJson({
      ...SessionEventData(
              at: DateTime.utc(2026),
              event: SessionEventType.unblockGranted,
              minutes: 5)
          .toJson(),
    });
    expect(back!.minutes, 5);
  });
}
