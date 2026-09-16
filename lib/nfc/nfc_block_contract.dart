// Contract between the NFC scanning side (Konstantin) and the
// app-blocking side (your friend) for the PoC.
//
// Neither side needs to know how the other one works internally.
// The NFC side only ever calls `onBlockStateChanged`; the blocking
// ignore: dangling_library_doc_comments
/// side only ever implements it. That's the whole handoff.
 
/// The two states this PoC cares about. Kept as an enum instead of a
/// bare bool so the demo/logs/UI can print something readable, and so
/// it's easy to add more states later (e.g. `pending`) without
/// changing every call site.
enum BlockState {
  unblocked,
  blocked,
}
 
/// Implemented by the app-blocking side.
///
/// Your friend writes a class that implements this and reacts to
/// state changes however their blocking mechanism actually works
/// (device admin APIs, screen time APIs, whatever they land on).
abstract class AppBlockerContract {
  /// Called exactly once per confirmed, matching tag scan, with the
  /// state the app should now be in. Called with `blocked` right
  /// after a scan that should start blocking, and `unblocked` right
  /// after a scan that should end it.
  ///
  /// This is a plain notification, not a request for permission —
  /// by the time this is called, the NFC side has already decided
  /// the tag was valid. The implementation should be idempotent:
  /// calling it twice with the same state (e.g. after an app
  /// restart) should be safe and just leave things as they are.
  void onBlockStateChanged(BlockState newState);
}
 
/// Implemented by the NFC scanning side (this is what Konstantin's
/// code exposes; a friend's blocking code only ever talks to this
/// through the contract above, never directly to NFC internals).
abstract class NfcSessionContract {
  /// Starts listening for tag scans. Call once, e.g. on app start
  /// or when entering the PoC screen.
  Future<void> startListening();
 
  /// Stops listening for tag scans. Call on app shutdown/screen exit.
  Future<void> stopListening();
 
  /// The current state, so the blocking side (or a UI) can check
  /// "are we blocked right now" without waiting for the next scan.
  BlockState get currentState;
}
 