import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/providers/repository_providers.dart';

import 'unblock_flow_screen.dart';

/// Wacht op een verzoek van het blokkeerscherm (Android): wie daar op "Open
/// Rest For More" tikt, komt hier met de geblokkeerde app en begint bij de
/// bewuste pauze. Kijkt bij het opstarten en elke keer dat de app weer naar
/// voren komt.
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

  @override
  Widget build(BuildContext context) => widget.child;
}
