import 'dart:io' as io;

import 'package:flutter/services.dart';

import '../../screens/moment_app_picker_screen.dart' show PickableApp, AppLoader;
import 'moment_blocking.dart';

/// De keuzes voor tijdelijk vrijgeven, zoals het Opal-ontwerp ze beschrijft.
abstract final class UnblockPolicy {
  /// Hoe lang de pauzeschermstap duurt. Niet over te slaan.
  static const pause = Duration(seconds: 5);

  /// Hoe lang een app maximaal vrij kan: genoeg voor één bericht of filmpje,
  /// te kort om in te verdwijnen.
  static const minutes = [1, 5, 10, 15];
}

/// Geeft apps tijdelijk vrij tijdens een lopende blokkade. Na afloop gaat de
/// blokkade vanzelf weer dicht.
///
/// Android geeft één app vrij: het toestel onthoudt tot wanneer en de
/// blokkade controleert dat bij elke gebeurtenis. iOS geeft geen namen van
/// apps vrij (de keuze is ondoorzichtig), dus daar wordt de hele blokkade even
/// gepauzeerd.
class UnblockService {
  UnblockService({
    MethodChannel? channel,
    bool? isAndroid,
    bool? isIos,
    DateTime Function()? now,
  })  : _channel = channel ?? blockingChannel,
        isAndroid = isAndroid ?? io.Platform.isAndroid,
        isIos = isIos ?? io.Platform.isIOS,
        _now = now ?? DateTime.now;

  final MethodChannel _channel;
  final bool isAndroid;
  final bool isIos;
  final DateTime Function() _now;

  /// Of de gebruiker eerst een app moet kiezen.
  bool get choosesApp => isAndroid;

  /// De apps die nu geblokkeerd zijn (Android), met hun naam als die bekend is.
  Future<List<PickableApp>> blockedApps(AppLoader loadApps) async {
    final packages = (await _channel.invokeMethod<List<dynamic>>(
              'getBlockedPackages',
            ) ??
            const [])
        .cast<String>();
    final installed = {for (final a in await loadApps()) a.id: a};
    return [
      for (final p in packages)
        installed[p] ?? PickableApp(name: p, id: p),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// Geeft [package] (Android) of de hele blokkade (iOS) [minutes] minuten vrij
  /// en geeft het eindtijdstip terug.
  Future<DateTime> grant({String? package, required int minutes}) async {
    if (!UnblockPolicy.minutes.contains(minutes)) {
      throw ArgumentError.value(minutes, 'minutes', 'niet toegestaan');
    }
    await _channel.invokeMethod<void>('grantUnblock', {
      'package': ?package,
      'minutes': minutes,
    });
    return _now().add(Duration(minutes: minutes));
  }

  /// Een verzoek om vrij te geven dat het blokkeerscherm heeft klaargezet
  /// (Android). Geeft de pakketnaam van de geblokkeerde app, een lege tekst
  /// als die onbekend is, of null als er geen verzoek is. Wordt één keer
  /// teruggegeven.
  Future<String?> takePendingRequest() async {
    if (!isAndroid) return null;
    return _channel.invokeMethod<String>('takePendingUnblock');
  }

  /// iOS: zet de blokkade terug als de vrijgegeven tijd voorbij is.
  Future<void> reapplyIfExpired() async {
    if (!isIos) return;
    await _channel.invokeMethod<void>('reapplyIfExpired');
  }
}
