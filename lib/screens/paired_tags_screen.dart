import 'package:rest4more/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:rest4more/data/tags/tag_service.dart';

import 'moments_widgets.dart';
import 'nfc_guide_screen.dart';
import 'today_screen.dart' show RestPalette, RestType;

class PairedTagsScreen extends StatefulWidget {
  const PairedTagsScreen({super.key});

  @override
  State<PairedTagsScreen> createState() => _PairedTagsScreenState();
}

class _PairedTagsScreenState extends State<PairedTagsScreen> {
  List<String> _tags = [];
  Map<String, String> _names = {};
  Map<String, int> _numbers = {};
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
      final names = await TagService.getTagNames();
      final numbers = await TagService.getTagNumbers(tags);
      if (!mounted) return;
      // Order by the permanent number so a tag keeps its place in the list.
      tags.sort((a, b) => numbers[a]!.compareTo(numbers[b]!));
      setState(() {
        _tags = tags;
        _names = names;
        _numbers = numbers;
      });
    } catch (e) {
      debugPrint('MethodChannel error: $e');
      if (mounted) {
        _showMessage(AppLocalizations.of(context).couldNotLoadTags);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _remove(String uuid) async {
    final l10n = AppLocalizations.of(context);
    try {
      await TagService.removeKnownTag(uuid);
      await _load();
    } catch (e) {
      debugPrint('MethodChannel error: $e');
      _showMessage(l10n.couldNotRemoveTag);
    }
  }

  String _displayName(String uuid) =>
      _names[uuid] ?? AppLocalizations.of(context).tagNumber(_numbers[uuid] ?? 1);

  Future<void> _rename(String uuid) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _RenameTagDialog(
        initial: _names[uuid] ?? '',
        hint: _displayName(uuid),
      ),
    );
    if (result == null) return;
    try {
      await TagService.setTagName(uuid, result);
      await _load();
    } catch (e) {
      debugPrint('Rename error: $e');
      _showMessage(l10n.couldNotRenameTag);
    }
  }

  Future<void> _addTag() async {
    final l10n = AppLocalizations.of(context);
    if (_scanning) return;
    final availability = await NfcManager.instance.checkAvailability();
    if (!mounted) return;
    if (availability != NfcAvailability.enabled) {
      _showMessage(availability == NfcAvailability.disabled
          ? l10n.nfcOff
          : l10n.nfcUnsupported);
      return;
    }

    setState(() => _scanning = true);
    try {
      await NfcManager.instance.startSession(
        pollingOptions: TagService.pollingOptions,
        alertMessageIos: l10n.holdNearTag,
        onSessionErrorIos: (error) {
          debugPrint('NFC session ended: ${error.code} ${error.message}');
          _scanning = false;
          if (!mounted) return;
          setState(() {});
          if (error.code !=
              NfcReaderErrorCodeIos.readerSessionInvalidationErrorUserCanceled) {
            _showMessage(l10n.scanningStopped(error.message));
          }
        },
        onDiscovered: (tag) async {
          String message;
          try {
            final uuid = TagService.uuidFromTag(tag);
            if (uuid == null) {
              message = l10n.tagNoLink;
            } else {
              await TagService.addKnownTag(uuid);
              message = l10n.tagAdded;
            }
          } catch (e) {
            debugPrint('Pairing error: $e');
            message = l10n.couldNotReadTag;
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
      _showMessage(l10n.couldNotStartScanning);
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
                    _scanning ? AppLocalizations.of(context).waitingForTag : AppLocalizations.of(context).addTag,
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
                      tooltip: AppLocalizations.of(context).back,
                      style: IconButton.styleFrom(
                        backgroundColor: RestPalette.surface,
                        foregroundColor: RestPalette.primary,
                        minimumSize: const Size(44, 44),
                      ),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    const SizedBox(width: 12),
                    Text(AppLocalizations.of(context).tabProfile, style: RestType.sans(15,
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
                Text(AppLocalizations.of(context).nfcTagsTitle, style: RestType.serif(44)),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).pairTagOnce,
                  style: RestType.sans(17, color: RestPalette.accent),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const NfcGuideScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.help_outline),
                  label: Text('How to use your NFC card',
                      style: RestType.sans(15,
                          color: RestPalette.primary,
                          weight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: RestPalette.primary,
                    side: const BorderSide(color: RestPalette.primary),
                    shape: const StadiumBorder(),
                    minimumSize: const Size(double.infinity, 54),
                  ),
                ),
                const SizedBox(height: 24),
                if (_scanning) ...[
                  _notice(AppLocalizations.of(context).holdPhoneAgainstTag,
                      action: TextButton(
                        onPressed: _cancelScan,
                        style: TextButton.styleFrom(
                            foregroundColor: RestPalette.primary),
                        child: Text(AppLocalizations.of(context).cancel, style: RestType.sans(14,
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
                  _notice(AppLocalizations.of(context).noTagsAddOne)
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
              Text(_displayName(uuid), style: RestType.serif(22)),
              Text(uuid.substring(0, 8),
                  style: RestType.sans(12, color: RestPalette.accent)),
            ],
          ),
        ),
        IconButton(
          tooltip: AppLocalizations.of(context).renameTag,
          onPressed: () => _rename(uuid),
          style: IconButton.styleFrom(
            foregroundColor: RestPalette.primary,
            minimumSize: const Size(48, 48),
          ),
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: AppLocalizations.of(context).removeTag,
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

/// Owns its controller so it is disposed together with the dialog, after the
/// close animation, instead of while the dialog is still on screen.
class _RenameTagDialog extends StatefulWidget {
  const _RenameTagDialog({required this.initial, required this.hint});

  final String initial;
  final String hint;

  @override
  State<_RenameTagDialog> createState() => _RenameTagDialogState();
}

class _RenameTagDialogState extends State<_RenameTagDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: RestPalette.background,
      title: Text(l10n.renameTag, style: RestType.serif(24)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 30,
        textCapitalization: TextCapitalization.sentences,
        style: RestType.sans(17, color: RestPalette.primary),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: RestType.sans(
            17,
            color: RestPalette.accent.withValues(alpha: 0.5),
          ),
        ),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
