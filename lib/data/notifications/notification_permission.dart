import 'package:flutter/services.dart';

/// Of de app meldingen mag tonen, zoals het besturingssysteem het ziet.
enum NotificationPermissionStatus {
  /// Meldingen zijn toegestaan.
  granted,

  /// Nog nooit gevraagd: het systeem laat bij een verzoek zijn eigen venster
  /// zien.
  notDetermined,

  /// Geweigerd, maar het systeem mag het nog een keer vragen (alleen Android).
  denied,

  /// Het systeem vraagt het niet meer. Alleen via de instellingen van het
  /// toestel weer aan te zetten.
  blocked,
}

/// Vraagt en controleert de toestemming voor meldingen. Vraagt nooit uit
/// zichzelf: alleen [request] laat het venster van het systeem zien.
abstract class NotificationPermission {
  const NotificationPermission();

  Future<NotificationPermissionStatus> status();

  /// Laat het venster van het systeem zien als dat nog kan, en geeft de
  /// toestand daarna. Bij [NotificationPermissionStatus.blocked] verschijnt er
  /// niets.
  Future<NotificationPermissionStatus> request();

  /// Opent de meldinginstellingen van de app. False als dat op dit toestel
  /// niet lukt.
  Future<bool> openSettings();
}

/// Praat met de eigen code in `SceneDelegate.swift` en `MainActivity.kt`.
class MethodChannelNotificationPermission extends NotificationPermission {
  const MethodChannelNotificationPermission();

  static const _channel = MethodChannel('rest4more/notifications');

  @override
  Future<NotificationPermissionStatus> status() async =>
      _parse(await _channel.invokeMethod<String>('status'));

  @override
  Future<NotificationPermissionStatus> request() async =>
      _parse(await _channel.invokeMethod<String>('request'));

  @override
  Future<bool> openSettings() async =>
      await _channel.invokeMethod<bool>('openSettings') ?? false;

  static NotificationPermissionStatus _parse(String? value) => switch (value) {
        'granted' => NotificationPermissionStatus.granted,
        'denied' => NotificationPermissionStatus.denied,
        'blocked' => NotificationPermissionStatus.blocked,
        _ => NotificationPermissionStatus.notDetermined,
      };
}
