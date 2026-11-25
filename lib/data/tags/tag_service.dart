import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TagService {
  static const _channel = MethodChannel(
    'com.example.app_blocking_prototype/blocking',
  );

  static const tagHost = 'tap.bartvangestel.nl';

  static final _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  );

  static const _uriPrefixes = {
    0x00: '',
    0x01: 'http://www.',
    0x02: 'https://www.',
    0x03: 'http://',
    0x04: 'https://',
  };

  static final _blockingChanges = StreamController<bool>.broadcast();
  static bool _listening = false;

  /// Fires when a tag link toggled blocking natively. The channel only has
  /// one Dart-side handler, so every screen listens through this stream.
  static Stream<bool> get blockingChanges {
    if (!_listening) {
      _listening = true;
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'blockingChanged' && call.arguments is bool) {
          _blockingChanges.add(call.arguments as bool);
        }
      });
    }
    return _blockingChanges.stream;
  }

  static Future<bool> getBlocking() async =>
      await _channel.invokeMethod<bool>('getBlocking') ?? false;

  static Future<void> setBlocking(bool value) =>
      _channel.invokeMethod('setBlocking', {'isBlocking': value});

  static Future<List<String>> getKnownTags() async {
    final list = await _channel.invokeMethod<List<dynamic>>('getKnownTags');
    return (list ?? []).cast<String>();
  }

  static Future<void> addKnownTag(String uuid) =>
      _channel.invokeMethod('addKnownTag', {'uuid': uuid});

  static Future<void> removeKnownTag(String uuid) =>
      _channel.invokeMethod('removeKnownTag', {'uuid': uuid});

  static const _namesKey = 'tag_names';
  static const _numbersKey = 'tag_numbers';
  static const _nextNumberKey = 'tag_next_number';

  /// User-chosen names by tag UUID. Tags without an entry have no custom name.
  static Future<Map<String, String>> getTagNames() async {
    final prefs = await SharedPreferences.getInstance();
    return _readMap(prefs, _namesKey).map((k, v) => MapEntry(k, v as String));
  }

  /// Saves [name] for [uuid]; a blank name clears it back to the default.
  static Future<void> setTagName(String uuid, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final names = _readMap(prefs, _namesKey);
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      names.remove(uuid);
    } else {
      names[uuid] = trimmed;
    }
    await prefs.setString(_namesKey, jsonEncode(names));
  }

  /// A permanent number per tag for its default name ("Tag 2"). Numbers are
  /// handed out once and never reused, so removing a tag does not renumber
  /// the others.
  static Future<Map<String, int>> getTagNumbers(Iterable<String> uuids) async {
    final prefs = await SharedPreferences.getInstance();
    final numbers = _readMap(prefs, _numbersKey);
    var next = prefs.getInt(_nextNumberKey) ?? 1;
    var changed = false;
    for (final uuid in uuids) {
      if (!numbers.containsKey(uuid)) {
        numbers[uuid] = next++;
        changed = true;
      }
    }
    if (changed) {
      await prefs.setString(_numbersKey, jsonEncode(numbers));
      await prefs.setInt(_nextNumberKey, next);
    }
    return {for (final u in uuids) u: numbers[u] as int};
  }

  static Map<String, dynamic> _readMap(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  /// Returns the lowercase UUID if [url] is one of our tag links, else null.
  static String? parseTagUuid(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host != tagHost) {
      return null;
    }
    final segments = uri.pathSegments;
    if (segments.length != 2 || segments[0] != 't') return null;
    final id = segments[1].toLowerCase();
    return _uuidPattern.hasMatch(id) ? id : null;
  }

  /// Reads the tag link from the first NDEF record (well-known type "U") and
  /// returns its UUID, or null if the tag does not hold one of our links.
  static String? uuidFromTag(NfcTag tag) {
    final message = Platform.isAndroid
        ? NdefAndroid.from(tag)?.cachedNdefMessage
        : NdefIos.from(tag)?.cachedNdefMessage;
    if (message == null || message.records.isEmpty) return null;
    final record = message.records.first;

    if (record.type.length != 1 || record.type.first != 0x55) return null;
    if (record.payload.isEmpty) return null;

    final prefix = _uriPrefixes[record.payload.first] ?? '';
    return parseTagUuid(prefix + utf8.decode(record.payload.sublist(1)));
  }

  /// Ends any NFC session still open, ignoring "no active session" errors.
  ///
  /// nfc_manager allows one session at a time and refuses to start a new one
  /// while it still holds an old one, so a session that was not closed
  /// cleanly (cancelled sheet, failed read, screen left mid-scan) blocks every
  /// later scan until the app restarts. Call this before starting a session
  /// and whenever a scan ends.
  static Future<void> stopSessionQuietly() =>
      NfcManager.instance.stopSession().catchError((_) {});

  /// Polling for ISO 14443 only: NTAG cards are ISO 14443, and polling for
  /// FeliCa makes iOS demand extra Info.plist keys.
  static const pollingOptions = {NfcPollingOption.iso14443};
}
