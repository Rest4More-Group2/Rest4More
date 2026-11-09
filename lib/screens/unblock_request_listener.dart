import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/providers/repository_providers.dart';

import 'session_run_screen.dart';
import 'unblock_flow_screen.dart';

/// Wacht op een verzoek van het blokkeerscherm (Android): wie daar op "Open
/// Rest For More" tikt, komt hier met de geblokkeerde app en begint bij de
/// bewuste pauze. Kijkt bij het opstarten en elke keer dat de app weer naar
/// voren komt.
///
/// Is de app afgesloten terwijl de apps tijdelijk vrij waren, dan komt bij het
/// opstarten de sessie terug, met het aftellen van de vrijgave erbovenop.
class UnblockRequestListener extends ConsumerStatefulWidget {
  const UnblockRequestListener({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  ConsumerState<UnblockRequestListener> createState() =>
      _UnblockRequestListenerState();
}

class _UnblockRequestListenerState extends ConsumerState<UnblockRequestListener>
    with WidgetsBindingObserver {
  bool _open = false;
  bool _restoreChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (_open) return;
    try {
      // iOS: zet een verlopen tijdelijke vrijgave weer dicht.
      await ref.read(unblockServiceProvider).reapplyIfExpired();
      if (await _restorePausedSession()) return;
      final request = await ref.read(unblockServiceProvider).takePendingRequest();
      final navigator = widget.navigatorKey.currentState;
      if (request == null || navigator == null || !mounted) return;
      _open = true;
      await navigator.push<void>(MaterialPageRoute<void>(
        builder: (_) => UnblockFlowScreen(
          initialPackage: request.isEmpty ? null : request,
        ),
      ));
    } on Object {
      // Geen verzoek of niet te lezen: er hoeft niets te gebeuren.
    } finally {
      _open = false;
    }
  }

  /// Alleen bij het opstarten: een sessie die midden in een vrijgave staat.
  Future<bool> _restorePausedSession() async {
    if (_restoreChecked) return false;
    _restoreChecked = true;
    final session = await ref.read(sessionRunnerProvider).current();
    final navigator = widget.navigatorKey.currentState;
    if (session == null ||
        !session.isPaused(DateTime.now()) ||
        navigator == null ||
        !mounted) {
      return false;
    }
    // Niet wachten: verzoeken van het blokkeerscherm blijven intussen welkom.
    navigator
        .push<void>(MaterialPageRoute<void>(
          builder: (_) => SessionRunScreen(resume: session),
        ))
        .ignore();
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
