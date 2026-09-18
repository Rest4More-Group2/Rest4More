import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NfcScanScreen extends StatefulWidget {
  const NfcScanScreen({super.key});

  @override
  State<NfcScanScreen> createState() => _NfcScanScreenState();
}

class _NfcScanScreenState extends State<NfcScanScreen> {
  static const platform = MethodChannel(
    'com.example.app_blocking_prototype/blocking',
  );

  String _status = 'Checking NFC...';
  bool _canScan = false;
  bool _isBlocked = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _isBlocked = ModalRoute.of(context)?.settings.arguments == true;
    _startScan();
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  Future<void> _startScan() async {
    final availability = await NfcManager.instance.checkAvailability();
    if (!mounted) return;

    if (availability != NfcAvailability.enabled) {
      setState(() {
        _canScan = false;
        _status = availability == NfcAvailability.disabled
            ? 'NFC is turned off. Enable it in your phone settings and come back.'
            : 'This device does not support NFC.';
      });
      return;
    }

    setState(() {
      _canScan = true;
      _status = _isBlocked
          ? 'Hold your phone against an NFC tag to unblock your apps'
          : 'Hold your phone against an NFC tag to block your apps';
    });

    await NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (tag) async {
        await NfcManager.instance.stopSession();
        await _toggleBlocking();
      },
    );
  }

  Future<void> _toggleBlocking() async {
    final newState = !_isBlocked;
    try {
      await platform.invokeMethod('setBlocking', {'isBlocking': newState});
      if (mounted) Navigator.pop(context, newState);
    } catch (e) {
      debugPrint('MethodChannel error: $e');
      if (mounted) {
        setState(() {
          _canScan = false;
          _status = 'Could not change blocking. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan NFC tag')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.nfc,
                size: 96,
                color: _canScan
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
              ),
              const SizedBox(height: 24),
              Text(_status, textAlign: TextAlign.center),
              if (!_canScan) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _startScan,
                  child: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
