import 'dart:io' as io;

import 'package:flutter/services.dart';

import 'moment_profiles.dart';

const MethodChannel blockingChannel =
    MethodChannel('com.example.app_blocking_prototype/blocking');

/// Zet blokkeren aan of uit voor één moment. Aan: eerst de apps van dat
/// moment doorgeven aan het besturingssysteem, dan pas blokkeren. Zo blokkeert
/// Reading nooit de apps van Focus.
class MomentBlocking {
  MomentBlocking(this._service, {MethodChannel? channel, bool? isIos, bool? isAndroid})
      : _channel = channel ?? blockingChannel,
        _isIos = isIos ?? io.Platform.isIOS,
        _isAndroid = isAndroid ?? io.Platform.isAndroid;

  final MomentProfileService _service;
  final MethodChannel _channel;
  final bool _isIos;
  final bool _isAndroid;

  /// [kind] is null voor het oude prototype zonder moment: dan geldt de
  /// gedeelde keuze van de oude kiezer.
  Future<void> setBlocking(MomentKind? kind, bool blocking) async {
    final args = <String, Object?>{'isBlocking': blocking};
    if (blocking && kind != null) {
      if (_isAndroid) {
        final profile = await _service.ensure(kind);
        await _channel.invokeMethod<void>('setBlockedPackages', {
          'blockedPackages':
              MomentProfileService.androidPackages(profile).toList(),
        });
      } else if (_isIos) {
        // Zonder bewaarde keuze blokkeert dit niets, en valt het niet terug
        // op de gedeelde keuze van een ander moment.
        args['momentSelection'] = true;
        args['selection'] = await _service.iosSelection(kind);
      }
    }
    await _channel.invokeMethod<void>('setBlocking', args);
  }
}
