import 'package:flutter/material.dart';
import 'package:rest4more/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/data/moments/moment_blocking.dart';
import 'package:rest4more/data/moments/moment_profiles.dart';
import 'package:rest4more/l10n/format.dart';
import 'package:rest4more/providers/repository_providers.dart';

import 'nfc_scan_screen.dart';
import 'session_run_screen.dart';
import 'today_screen.dart' show RestPalette, RestType;

/// Starts the routine immediately rather than waiting for its scheduled time.
/// Regular routines use the existing logged session runner and timer.
/// Strict evenings never unlock automatically: a scan is required.
class ManualRoutineScreen extends StatelessWidget {
  const ManualRoutineScreen({
    super.key,
    required this.kind,
    required this.minutes,
    required this.strict,
  });

  final MomentKind kind;
  final int minutes;
  final bool strict;

  @override
  Widget build(BuildContext context) {
    if (strict) return _StrictManualEvening(kind: kind);
    return SessionRunScreen(manualKind: kind, manualMinutes: minutes);
  }
}

class _StrictManualEvening extends ConsumerStatefulWidget {
  const _StrictManualEvening({required this.kind});
  final MomentKind kind;

  @override
  ConsumerState<_StrictManualEvening> createState() =>
      _StrictManualEveningState();
}

class _StrictManualEveningState extends ConsumerState<_StrictManualEvening> {
  bool _busy = true;
  bool _active = false;
  String? _error;

  MomentBlocking get _blocking =>
      MomentBlocking(ref.read(momentProfileServiceProvider));

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_start);
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _blocking.setBlocking(widget.kind, true);
      if (mounted) setState(() => _active = true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).blockStartFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scanToEnd() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const NfcScanScreen(),
        settings: RouteSettings(
          arguments: (isBlocked: true, moment: widget.kind),
        ),
      ),
    );
    if (!mounted) return;
    if (result == false) {
      setState(() => _active = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: RestPalette.background,
    appBar: AppBar(
      title: Text(momentKindName(AppLocalizations.of(context), widget.kind)),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context).yourEvening,
              style: RestType.serif(36),
            ),
            const SizedBox(height: 18),
            if (_busy) const Center(child: CircularProgressIndicator()),
            if (_error != null) Text(_error!, style: RestType.sans(16)),
            if (_active)
              Text(
                AppLocalizations.of(context).strictEveningActive,
                style: RestType.sans(16),
              ),
            if (!_busy) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _error != null
                    ? _start
                    : _active
                    ? _scanToEnd
                    : () => Navigator.pop(context),
                child: Text(
                  _error != null
                      ? AppLocalizations.of(context).tryAgain
                      : _active
                      ? AppLocalizations.of(context).scanNfcToEnd
                      : AppLocalizations.of(context).done,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
