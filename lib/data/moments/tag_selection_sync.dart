import 'dart:io' as io;

import 'package:flutter/services.dart';

import 'moment_blocking.dart';
import 'moment_profiles.dart';

/// Geeft de appkeuze van het Tag-moment door aan het toestel zelf.
///
/// Een tag kan de blokkade ook starten terwijl de app dicht is (een link die de
/// app opent, of een achtergrondactiviteit). Dan draait er geen Flutter en is
/// de database niet te lezen, dus het toestel bewaart zelf een kopie van de
/// keuze. Die kopie is alleen voor de tag: andere momenten gebruiken haar niet.
class TagSelectionSync {
  TagSelectionSync(
    this._service, {
    MethodChannel? channel,
    bool? isIos,
    bool? isAndroid,
  })  : _channel = channel ?? blockingChannel,
        _isIos = isIos ?? io.Platform.isIOS,
        _isAndroid = isAndroid ?? io.Platform.isAndroid;

  final MomentProfileService _service;
  final MethodChannel _channel;
  final bool _isIos;
  final bool _isAndroid;

  /// Zet de bewaarde keuze van Tag op het toestel. Zonder keuze wordt de kopie
  /// leeg, zodat een tag dan niets blokkeert.
  Future<void> mirror() async {
    if (_isAndroid) {
      final profile = await _service.ensure(MomentKind.tag);
      await _channel.invokeMethod<void>('setTagSelection', {
        'packages': MomentProfileService.androidPackages(profile).toList(),
      });
    } else if (_isIos) {
      await _channel.invokeMethod<void>('setTagSelection', {
        'selection': await _service.iosSelection(MomentKind.tag),
      });
    }
  }
}
