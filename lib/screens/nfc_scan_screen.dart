import 'package:flutter/material.dart';
import 'package:rest4more/l10n/app_localizations.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/data/moments/moment_blocking.dart';
import 'package:rest4more/data/moments/moment_profiles.dart';
import 'package:rest4more/providers/repository_providers.dart';
import 'package:rest4more/theme/app_color.dart';

class NfcScanScreen extends StatefulWidget {
  const NfcScanScreen({super.key});

  @override
  State<NfcScanScreen> createState() => _NfcScanScreenState();
}

class _NfcScanScreenState extends State<NfcScanScreen> {
  /// Null zolang NFC nog wordt gecontroleerd.
  String? _status;
  bool _canScan = false;
  bool _isBlocked = false;
  bool _started = false;
  bool _sessionActive = false;
  MomentKind? _moment;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ({bool isBlocked, MomentKind? moment})) {
      _isBlocked = args.isBlocked;
      _moment = args.moment;
    } else {
      _isBlocked = args == true;
    }
    _startScan();
  }

  @override
  void dispose() {
    if (_sessionActive) {
      _sessionActive = false;
      NfcManager.instance.stopSession().catchError((_) {});
    }
    super.dispose();
  }

  Future<void> _startScan() async {
    final availability = await NfcManager.instance.checkAvailability();
    if (!mounted) return;

    if (availability != NfcAvailability.enabled) {
      setState(() {
        _canScan = false;
        final l10n = AppLocalizations.of(context);
        _status = availability == NfcAvailability.disabled
            ? l10n.nfcDisabled
            : l10n.nfcUnsupported;
      });
      return;
    }

    setState(() {
      _canScan = true;
      final l10n = AppLocalizations.of(context);
      _status = _isBlocked ? l10n.nfcHoldToUnblock : l10n.nfcHoldToBlock;
    });

    _sessionActive = true;
    await NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (tag) async {
        _sessionActive = false;
        await NfcManager.instance.stopSession();
        await _toggleBlocking();
      },
    );
  }

  Future<void> _toggleBlocking() async {
    final newState = !_isBlocked;
    try {
      await MomentBlocking(
        ProviderScope.containerOf(context).read(momentProfileServiceProvider),
      ).setBlocking(_moment, newState);
      if (mounted) Navigator.pop(context, newState);
    } catch (e) {
      debugPrint('MethodChannel error: $e');
      if (mounted) {
        setState(() {
          _canScan = false;
          _status = AppLocalizations.of(context).nfcChangeFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.decoration,
        foregroundColor: AppColors.background,
        title: Text(AppLocalizations.of(context).nfcScanTitle),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.nfc,
                size: 96,
                color: _canScan ? AppColors.primaryAction : AppColors.panel,
              ),
              const SizedBox(height: 24),
              Text(
                _status ?? AppLocalizations.of(context).nfcChecking,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.text),
              ),
              if (!_canScan) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _startScan,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryAction,
                    side: BorderSide(color: AppColors.primaryAction),
                  ),
                  child: Text(AppLocalizations.of(context).tryAgain),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
