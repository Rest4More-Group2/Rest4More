import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:rest4more/data/tags/tag_service.dart';

import 'app_selection.dart';
import 'moments_widgets.dart';
import 'paired_tags_screen.dart';
import 'today_screen.dart' show RestPalette, RestType;

/// A Focus-like moment where your chosen apps are put aside with a tap of a
/// paired tag. While it is on, only a paired tag can end it.
class TagMomentScreen extends StatefulWidget {
  const TagMomentScreen({super.key});

  @override
  State<TagMomentScreen> createState() => _TagMomentScreenState();
}

class _TagMomentScreenState extends State<TagMomentScreen>
    with WidgetsBindingObserver {
  bool _active = false;
  bool _loading = true;
  bool _scanning = false;
  int _tagCount = 0;
  StreamSubscription<bool>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = TagService.blockingChanges.listen((blocking) {
      if (mounted) setState(() => _active = blocking);
    });
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    if (_scanning) {
      _scanning = false;
      NfcManager.instance.stopSession().catchError((_) {});
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final active = await TagService.getBlocking();
      final tags = await TagService.getKnownTags();
      if (!mounted) return;
      setState(() {
        _active = active;
        _tagCount = tags.length;
      });
    } catch (e) {
      debugPrint('MethodChannel error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _chooseApps() async {
    await openAppSelection(context);
  }

  Future<void> _pairTag() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const PairedTagsScreen()),
    );
    if (mounted) await _load();
  }

  Future<void> _scan() async {
    if (_scanning) return;
    final availability = await NfcManager.instance.checkAvailability();
    if (!mounted) return;
    if (availability != NfcAvailability.enabled) {
      _message(availability == NfcAvailability.disabled
          ? 'NFC is turned off. Enable it in your phone settings.'
          : 'This device does not support NFC.');
      return;
    }

    setState(() => _scanning = true);
    try {
      await NfcManager.instance.startSession(
        pollingOptions: TagService.pollingOptions,
        alertMessageIos: _active
            ? 'Hold your iPhone near your tag to end'
            : 'Hold your iPhone near your tag to begin',
        onSessionErrorIos: (error) {
          debugPrint('NFC session ended: ${error.code} ${error.message}');
          _scanning = false;
          if (!mounted) return;
          setState(() {});
          if (error.code !=
              NfcReaderErrorCodeIos.readerSessionInvalidationErrorUserCanceled) {
            _message('Scanning stopped: ${error.message}');
          }
        },
        onDiscovered: (tag) async {
          String? message;
          try {
            final uuid = TagService.uuidFromTag(tag);
            final known = await TagService.getKnownTags();
            if (uuid == null || !known.contains(uuid)) {
              message = 'This is not one of your paired tags.';
            } else {
              final next = !_active;
              await TagService.setBlocking(next);
              if (mounted) setState(() => _active = next);
            }
          } catch (e) {
            debugPrint('Tag scan error: $e');
            message = 'Could not read this tag. Please try again.';
          } finally {
            _scanning = false;
            await NfcManager.instance.stopSession();
          }
          if (!mounted) return;
          setState(() {});
          if (message != null) _message(message);
        },
      );
    } catch (e) {
      debugPrint('NFC error: $e');
      _scanning = false;
      _message('Could not start scanning.');
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasTags = _tagCount > 0;
    final primaryLabel = _scanning
        ? 'Waiting for tag…'
        : !hasTags
            ? 'Pair a tag first'
            : _active ? 'Scan tag to end' : 'Scan tag to begin';

    return Scaffold(
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
                onPressed: _loading || _scanning
                    ? null
                    : hasTags ? _scan : _pairTag,
                style: FilledButton.styleFrom(
                  backgroundColor: RestPalette.primary,
                  foregroundColor: RestPalette.background,
                  disabledBackgroundColor: RestPalette.surface,
                  disabledForegroundColor: RestPalette.accent,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  minimumSize: const Size(double.infinity, 58),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 26, vertical: 16),
                ),
                child: Row(
                  children: [
                    Text(primaryLabel, style: RestType.sans(17,
                        weight: FontWeight.w600,
                        color: _loading || _scanning
                            ? RestPalette.accent : RestPalette.background)),
                    const Spacer(),
                    Icon(hasTags ? Icons.nfc : Icons.arrow_forward, size: 24),
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
                        tooltip: 'Back to Moments',
                        style: IconButton.styleFrom(
                          backgroundColor: RestPalette.surface,
                          foregroundColor: RestPalette.primary,
                          minimumSize: const Size(44, 44),
                        ),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      const SizedBox(width: 12),
                      Text('Moments', style: RestType.sans(15,
                          color: RestPalette.primary,
                          weight: FontWeight.w600)),
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
                          index: 4, color: RestPalette.primary, size: 30),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Tag', style: RestType.serif(44)),
                  const SizedBox(height: 12),
                  Text(
                    'Put your apps aside with a tap, and bring them back '
                    'with the same tag.',
                    style: RestType.sans(17, color: RestPalette.accent),
                  ),
                  const SizedBox(height: 24),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: RestPalette.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        width: 2,
                        color: _active
                            ? RestPalette.primary : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TAG MOMENT', style: RestType.sans(11,
                            color: RestPalette.accent,
                            weight: FontWeight.w600)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: Text(
                              _loading ? 'Checking' : _active ? 'Active' : 'Not active',
                              style: RestType.serif(28),
                            )),
                            Icon(_active ? Icons.shield : Icons.shield_outlined,
                                color: RestPalette.primary, size: 26),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _active
                              ? 'Your apps are set aside. Only your tag can '
                                'end this moment.'
                              : hasTags
                                  ? 'Ready when you are. Scan your tag to set '
                                    'your apps aside.'
                                  : 'Pair a tag to use this moment.',
                          style: RestType.sans(14),
                        ),
                      ],
                    ),
                  ),
                  if (!_active) ...[
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: _chooseApps,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: RestPalette.primary,
                        shape: const StadiumBorder(),
                        side: const BorderSide(color: RestPalette.primary),
                        minimumSize: const Size(double.infinity, 56),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.apps_outlined, size: 22),
                          const SizedBox(width: 12),
                          Expanded(child: Text('Choose apps to set aside',
                              style: RestType.sans(15,
                                  color: RestPalette.primary,
                                  weight: FontWeight.w600))),
                          const Icon(Icons.chevron_right, size: 22),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: RestPalette.surface,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('How it works', style: RestType.serif(27)),
                        const SizedBox(height: 18),
                        _step(1, 'Choose the apps you want to set aside.'),
                        const SizedBox(height: 16),
                        _step(2, 'Scan your tag to begin.'),
                        const SizedBox(height: 16),
                        _step(3, 'Scan the same tag again to end.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text('A GENTLE REMINDER', textAlign: TextAlign.center,
                      style: RestType.sans(12,
                          color: RestPalette.accent,
                          weight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Text('“Put it down. Pick it up when you choose.”',
                      textAlign: TextAlign.center,
                      style: RestType.serif(24)
                          .copyWith(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _step(int number, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: RestPalette.background,
          shape: BoxShape.circle,
        ),
        child: Text('$number', style: RestType.sans(13,
            color: RestPalette.primary, weight: FontWeight.w600)),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(text, style: RestType.sans(15)),
        ),
      ),
    ],
  );
}
