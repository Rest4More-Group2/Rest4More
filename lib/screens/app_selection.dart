import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'accessibility_access_screen.dart';
import 'app_picker_screen.dart';
import 'authorization_ios_screen.dart';

const _channel = MethodChannel('com.example.app_blocking_prototype/blocking');

/// Opens the place where the user chooses which apps to set aside.
///
/// Android: our own list. iOS: Apple's picker straight away when Screen Time
/// access is already approved, otherwise the access screen first.
Future<void> openAppSelection(BuildContext context) async {
  final navigator = Navigator.of(context);
  if (io.Platform.isAndroid) {
    // Blocking needs the accessibility service, so ask for it first.
    var enabled = false;
    try {
      enabled = await _channel.invokeMethod<bool>('isAccessibilityEnabled') ??
          false;
    } catch (e) {
      debugPrint('Accessibility check error: $e');
    }
    await navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => enabled
            ? const AppPickerScreen()
            : const AccessibilityAccessScreen(),
      ),
    );
    return;
  }

  try {
    final status = await _channel.invokeMethod<String>(
      'checkAuthorizationStatus',
    );
    if (status == 'approved') {
      await _channel.invokeMethod('showAppPicker');
      return;
    }
  } catch (e) {
    debugPrint('App selection error: $e');
  }
  await navigator.push<void>(
    MaterialPageRoute<void>(builder: (_) => const AuthorizationIosScreen()),
  );
}
