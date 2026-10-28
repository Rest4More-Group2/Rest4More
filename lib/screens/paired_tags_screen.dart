import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:rest4more/data/tags/tag_service.dart';

import 'moments_widgets.dart';
import 'today_screen.dart' show RestPalette, RestType;

class PairedTagsScreen extends StatefulWidget {
  const PairedTagsScreen({super.key});

  @override
  State<PairedTagsScreen> createState() => _PairedTagsScreenState();
}

class _PairedTagsScreenState extends State<PairedTagsScreen> {
  List<String> _tags = [];
  bool _loading = true;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    if (_scanning) {
      _scanning = false;
      NfcManager.instance.stopSession().catchError((_) {});
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final tags = await TagService.getKnownTags();
      if (!mounted) return;
      setState(() => _tags = tags..sort());
    } catch (e) {
      debugPrint('MethodChannel error: $e');
      _showMessage('Could not load your tags.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _remove(String uuid) async {
    try {
      await TagService.removeKnownTag(uuid);
      await _load();
    } catch (e) {
      debugPrint('MethodChannel error: $e');
      _showMessage('Could not remove the tag.');
    }
  }

  Future<void> _addTag() async {
    if (_scanning) return;
    final availability = await NfcManager.instance.checkAvailability();
    if (!mounted) return;
    if (availability != NfcAvailability.enabled) {
      _showMessage(availability == NfcAvailability.disabled
          ? 'NFC is turned off. Enable it in your phone settings.'
          : 'This device does not support NFC.');
      return;
    }

    setState(() => _scanning = true);
    try {
      await NfcManager.instance.startSession(
        pollingOptions: TagService.pollingOptions,
        alertMessageIos: 'Hold your iPhone near the tag',
        onSessionErrorIos: (error) {
          debugPrint('NFC session ended: ${error.code} ${error.message}');
          _scanning = false;
          if (!mounted) return;
          setState(() {});
          if (error.code !=
              NfcReaderErrorCodeIos.readerSessionInvalidationErrorUserCanceled) {
            _showMessage('Scanning stopped: ${error.message}');
          }
        },
        onDiscovered: (tag) async {
          String message;
          try {
            final uuid = TagService.uuidFromTag(tag);
            if (uuid == null) {
              message = 'This tag does not hold a Rest4More link.';
            } else {
              await TagService.addKnownTag(uuid);
              message = 'Tag added.';
            }
          } catch (e) {
            debugPrint('Pairing error: $e');
            message = 'Could not read this tag. Please try again.';
          } finally {
            _scanning = false;
            await NfcManager.instance.stopSession();
          }
          if (!mounted) return;
          setState(() {});
          _showMessage(message);
          await _load();
        },
      );
    } catch (e) {
      debugPrint('NFC error: $e');
      _scanning = false;
      _showMessage('Could not start scanning.');
      if (mounted) setState(() {});
    }
  }

  Future<void> _cancelScan() async {
    _scanning = false;
    setState(() {});
    await NfcManager.instance.stopSession().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: RestPalette.background,
    bottomNavigationBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: FilledButton(
              onPressed: _scanning || _loading ? null : _addTag,
              style: FilledButton.styleFrom(
                backgroundColor: RestPalette.primary,
                foregroundColor: RestPalette.background,
                disabledBackgroundColor: RestPalette.surface,
                disabledForegroundColor: RestPalette.accent,
                elevation: 0,
                shape: const StadiumBorder(),
                minimumSize: const Size(double.infinity, 58),
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              ),
              child: Row(
                children: [
                  Text(
                    _scanning ? 'Waiting for tag…' : 'Add tag',
                    style: RestType.sans(17, weight: FontWeight.w600,
                        color: _scanning
                            ? RestPalette.accent : RestPalette.background),
                  ),
                  const Spacer(),
                  const Icon(Icons.add, size: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    body: SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Back',
                      style: IconButton.styleFrom(
                        backgroundColor: RestPalette.surface,
                        foregroundColor: RestPalette.primary,
                        minimumSize: const Size(44, 44),
                      ),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    const SizedBox(width: 12),
                    Text('Profile', style: RestType.sans(15,
                        color: RestPalette.primary, weight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: RestPalette.surface,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const RestMomentIcon(
                      index: 4,
                      color: RestPalette.primary,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('NFC tags', style: RestType.serif(44)),
                const SizedBox(height: 12),
                Text(
                  'Pair a tag once. Then a tap starts or ends your Tag moment.',
                  style: RestType.sans(17, color: RestPalette.accent),
                ),
                const SizedBox(height: 24),
                if (_scanning) ...[
                  _notice('Hold your phone against the tag you want to add.',
                      action: TextButton(
                        onPressed: _cancelScan,
                        style: TextButton.styleFrom(
                            foregroundColor: RestPalette.primary),
                        child: Text('Cancel', style: RestType.sans(14,
                            color: RestPalette.primary,
                            weight: FontWeight.w600)),
                      )),
                  const SizedBox(height: 16),
                ],
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: RestPalette.primary),
                    ),
                  )
                else if (_tags.isEmpty)
                  _notice('No tags paired yet. Add one to get started.')
                else
                  for (var i = 0; i < _tags.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    _tagRow(i, _tags[i]),
                  ],
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _notice(String text, {Widget? action}) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: RestPalette.surface,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        Expanded(child: Text(text, style: RestType.sans(15))),
        ?action,
      ],
    ),
  );

  Widget _tagRow(int index, String uuid) => Container(
    padding: const EdgeInsets.fromLTRB(18, 10, 8, 10),
    decoration: BoxDecoration(
      color: RestPalette.surface,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        const RestMomentIcon(index: 4, color: RestPalette.primary, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tag ${index + 1}', style: RestType.serif(22)),
              Text(uuid.substring(0, 8),
                  style: RestType.sans(12, color: RestPalette.accent)),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Remove tag',
          onPressed: () => _remove(uuid),
          style: IconButton.styleFrom(
            foregroundColor: RestPalette.primary,
            minimumSize: const Size(48, 48),
          ),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
  );
}
