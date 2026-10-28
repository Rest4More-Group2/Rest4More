import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest4more/data/moments/unblock_service.dart';
import 'package:rest4more/providers/repository_providers.dart';
import 'package:rest4more/screens/moment_app_picker_screen.dart';
import 'package:rest4more/screens/unblock_flow_screen.dart';

import 'onboarding_test_support.dart';

Future<List<PickableApp>> _apps() async => const [
      PickableApp(name: 'Instagram', id: 'com.insta'),
      PickableApp(name: 'Mail', id: 'com.mail'),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/unblock-flow');
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'getBlockedPackages') {
        return ['com.insta', 'com.mail'];
      }
      return null;
    });
  });

  Future<void> open(
    WidgetTester tester, {
    bool android = true,
    String? initialPackage,
    VoidCallback? onPop,
  }) async {
    final service = UnblockService(
      channel: channel,
      isAndroid: android,
      isIos: !android,
      now: () => DateTime(2026, 10, 12, 14, 0),
    );
    await pumpScreen(
      tester,
      ProviderScope(
        overrides: [unblockServiceProvider.overrideWithValue(service)],
        child: UnblockFlowScreen(
          initialPackage: initialPackage,
          loadApps: _apps,
          pause: const Duration(milliseconds: 500),
          now: () => DateTime(2026, 10, 12, 14, 0),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool continueIsActive(WidgetTester tester) {
    final ignore = tester.widget<IgnorePointer>(find
        .ancestor(
            of: find.text('Continue'), matching: find.byType(IgnorePointer))
        .first);
    return !ignore.ignoring;
  }

  screenTest('de hele route: kies, pauzeer, duur, ontgrendel', (tester) async {
    await open(tester);

    // Kies de app.
    expect(find.text('Which app do you need?'), findsOneWidget);
    await tester.tap(find.text('Instagram'));
    await tester.pump();

    // De pauze: niets te doen, en pas daarna Continue.
    expect(find.text('Take a moment to breathe'), findsOneWidget);
    expect(continueIsActive(tester), isFalse);
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('How long do you really need?'), findsNothing,
        reason: 'Continue kan niet worden overgeslagen');

    await tester.pump(const Duration(milliseconds: 600));
    expect(continueIsActive(tester), isTrue);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // De duur: 5 minuten staat standaard gekozen, met de eindtijd erbij.
    expect(find.text('How long do you really need?'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Instagram will be available until 14:05.'),
        findsOneWidget);
    expect(calls.where((c) => c.method == 'grantUnblock'), isEmpty,
        reason: 'nog niets vrijgegeven');

    await tester.tap(find.text('Unblock'));
    await tester.pumpAndSettle();

    final grant = calls.singleWhere((c) => c.method == 'grantUnblock');
    expect(grant.arguments, {'package': 'com.insta', 'minutes': 5});
    expect(find.text('Unblocked'), findsOneWidget);
    expect(find.textContaining('until 14:05'), findsOneWidget);
    expect(find.textContaining('locks again by itself'), findsOneWidget);
  });

  screenTest('een app die al bekend is slaat het kiezen over', (tester) async {
    await open(tester, initialPackage: 'com.mail');
    expect(find.text('Which app do you need?'), findsNothing);
    expect(find.text('Take a moment to breathe'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Mail will be available until 14:05.'), findsOneWidget);
  });

  screenTest('annuleren geeft niets vrij', (tester) async {
    await open(tester);
    await tester.tap(find.text('Instagram'));
    await tester.pump();
    await tester.tap(find.byTooltip('Cancel and keep it blocked'));
    await tester.pumpAndSettle();
    expect(calls.where((c) => c.method == 'grantUnblock'), isEmpty);
  });

  screenTest('iOS: geen app kiezen, de hele blokkade pauzeert', (tester) async {
    await open(tester, android: false);
    expect(find.text('Which app do you need?'), findsNothing);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Your apps will be available until 14:05.'),
        findsOneWidget);
    await tester.tap(find.text('Unblock'));
    await tester.pumpAndSettle();
    expect(calls.singleWhere((c) => c.method == 'grantUnblock').arguments,
        {'minutes': 5});
    expect(find.textContaining('Your apps are available until'), findsOneWidget);
  });

  screenTest('mislukt vrijgeven: duidelijke fout en je kunt opnieuw proberen',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'getBlockedPackages') return ['com.insta'];
      if (call.method == 'grantUnblock') throw PlatformException(code: 'x');
      return null;
    });
    await open(tester, initialPackage: 'com.insta');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unblock'));
    await tester.pumpAndSettle();
    expect(find.textContaining('could not unblock'), findsOneWidget);
    expect(find.text('Unblocked'), findsNothing);
    expect(find.text('Unblock'), findsOneWidget, reason: 'opnieuw mogelijk');
  });

  screenTest('niets geblokkeerd: dat staat er eerlijk', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'getBlockedPackages') return <String>[];
      return null;
    });
    await open(tester);
    expect(find.text('Nothing is blocked right now.'), findsOneWidget);
  });
}
