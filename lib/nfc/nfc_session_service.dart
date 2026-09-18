import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

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
  /// separators, e.g. '049A9B12541B90'. Confirmed for your door tag
  /// via NFC Tools' "Serial number" field.
  final String expectedTagUid;

  /// Whoever implements the blocking side. This service calls
  /// `blocker.onBlockStateChanged(...)` and nothing else on it.
  final AppBlockerContract blocker;

  BlockState _state = BlockState.unblocked;

  @override
  BlockState get currentState => _state;

  @override
  Future<void> startListening() async {
    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      // Either no NFC hardware, or the user has it turned off in
      // system settings. Printing is enough for the PoC; a real app
      // would surface this in the UI instead.
      print('NFC is not available: $availability');
      return;
    }

    await NfcManager.instance.startSession(
      // Your door tag is ISO14443 (Type A / MIFARE DESFire), so that
      // alone would suffice, but listening for all three families
      // costs nothing and means any tag you try later just works too.
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
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

    // A session only handles one tap and then closes itself; restart
    // it so the next tap is picked up too. Doing this unconditionally
    // keeps Android and iOS on the same code path.
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

  /// Pulls the UID out of whichever typed tag technology was
  /// detected. Different tag families (and platforms) expose the
  /// identifier through different classes — this checks the ones
  /// relevant to your door tag (ISO14443 Type A / MIFARE DESFire,
  /// which shows up as NfcA and often IsoDep on Android, and as
  /// Iso7816/MiFare on iOS) plus a couple of common fallbacks.
  ///
  /// If a tag you try later isn't covered, the print statement in
  /// [startListening]'s caller (or adding one here) combined with
  /// `tag` itself in the debugger will show which technology it
  /// actually came in as.
  String? _extractUid(NfcTag tag) {
    // Android — the UID lives on the shared NfcTagAndroid.id field,
    // reached via each technology's own `.tag` property, not a
    // direct `.identifier` getter.
    final nfcA = NfcAAndroid.from(tag);
    if (nfcA != null) return _bytesToHex(nfcA.tag.id);

    final nfcB = NfcBAndroid.from(tag);
    if (nfcB != null) return _bytesToHex(nfcB.tag.id);

    final nfcF = NfcFAndroid.from(tag);
    if (nfcF != null) return _bytesToHex(nfcF.tag.id);

    final nfcV = NfcVAndroid.from(tag);
    if (nfcV != null) return _bytesToHex(nfcV.tag.id);

    // iOS — these classes DO expose `.identifier` directly.
    final miFareIos = MiFareIos.from(tag);
    if (miFareIos != null) return _bytesToHex(miFareIos.identifier);

    final iso15693Ios = Iso15693Ios.from(tag);
    if (iso15693Ios != null) return _bytesToHex(iso15693Ios.identifier);

    return null;
  }

  String _bytesToHex(List<int> bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }
}