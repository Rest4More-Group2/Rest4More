import 'package:nfc_manager/nfc_manager.dart';

import 'nfc_block_contract.dart';

/// Concrete implementation of [NfcSessionContract] for the PoC.
///
/// Responsibilities, and only these:
///  - listen for NFC taps
///  - check the tapped tag's UID against the one known tag we accept
///  - flip [currentState] and notify the blocking side via the
///    [AppBlockerContract] it was given
///
/// It does NOT know anything about how blocking actually works —
/// that's the whole point of depending on the contract interface
/// instead of a concrete blocker class.
class NfcSessionService implements NfcSessionContract {
  NfcSessionService({
    required this.expectedTagUid,
    required this.blocker,
  });

  /// The one tag this PoC accepts, as an uppercase hex string with no
  /// separators, e.g. '04A2B3C4D5E680'. Get this value by running
  /// [startListening] once with logging on, tapping your door tag,
  /// and reading the UID it prints — then hardcode it here via the
  /// constructor from wherever you build this service (e.g. main.dart).
  final String expectedTagUid;

  /// Whoever implements the blocking side. This service calls
  /// `blocker.onBlockStateChanged(...)` and nothing else on it.
  final AppBlockerContract blocker;

  BlockState _state = BlockState.unblocked;

  @override
  BlockState get currentState => _state;

  @override
  Future<void> startListening() async {
    final isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      // No NFC hardware, or it's turned off in system settings.
      // For the PoC, printing is enough; a real app would show this
      // in the UI instead.
      print('NFC is not available on this device.');
      return;
    }

    await NfcManager.instance.startSession(
      onDiscovered: _handleTagDiscovered,
    );
  }

  @override
  Future<void> stopListening() async {
    await NfcManager.instance.stopSession();
  }

  Future<void> _handleTagDiscovered(NfcTag tag) async {
    final uid = _extractUid(tag);

    if (uid == null) {
      print('Could not read a UID from this tag — unsupported tag type?');
    } else if (uid == expectedTagUid) {
      _toggleState();
    } else {
      print('Ignored tag with UID $uid (does not match expected tag).');
    }

    // On iOS in particular, a session only handles ONE tap and then
    // must be explicitly stopped and restarted to accept the next
    // one. Doing this unconditionally keeps Android and iOS on the
    // same code path.
    await NfcManager.instance.stopSession();
    await startListening();
  }

  void _toggleState() {
    _state = _state == BlockState.unblocked
        ? BlockState.blocked
        : BlockState.unblocked;

    print('Matching tag scanned. New state: $_state');
    blocker.onBlockStateChanged(_state);
  }

  /// Pulls the UID out of the tag's raw platform data and formats it
  /// as an uppercase hex string, e.g. '04A2B3C4D5E680'.
  ///
  /// `tag.data` is a plain Map whose shape depends on which tag
  /// technology and OS detected it — there is no single typed class
  /// that works everywhere in this package version. This checks the
  /// common places the identifier shows up. If your specific door tag
  /// isn't covered, temporarily add `print(tag.data);` at the top of
  /// this method, tap the tag, and read the map that gets printed to
  /// find the right key — then add a branch for it below.
  String? _extractUid(NfcTag tag) {
    final raw = tag.data;
    if (raw is! Map) return null;

    // Some platforms put the id directly at the top level.
    if (raw['id'] is List) {
      return _bytesToHex(List<int>.from(raw['id'] as List));
    }

    // Otherwise it's nested under a technology-specific key.
    const techKeys = [
      'nfca',
      'nfcb',
      'nfcf', 
      'nfcv',
      'isodep',
      'mifareclassic',
      'mifareultralight',
      'iso15693',
      'miFare', // iOS-style key casing seen in some versions
    ];

    for (final key in techKeys) {
      final tech = raw[key];
      if (tech is Map && tech['identifier'] is List) {
        return _bytesToHex(List<int>.from(tech['identifier'] as List));
      }
    }

    return null;
  }

  String _bytesToHex(List<int> bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }
}