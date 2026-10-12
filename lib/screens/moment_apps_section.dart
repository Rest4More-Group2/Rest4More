import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/moments/moment_profiles.dart';
import 'package:rest4more/providers/repository_providers.dart';

import 'moment_app_picker_screen.dart';
import 'moments_form_widgets.dart';
import 'today_screen.dart' show RestPalette, RestType;

final _momentProfileProvider =
    StreamProvider.autoDispose.family<BlockProfile?, MomentKind>(
  (ref, kind) => ref.watch(momentProfileServiceProvider).watch(kind),
);

const MethodChannel _blockingChannel =
    MethodChannel('com.example.app_blocking_prototype/blocking');

/// Sectie "Apps to block" voor een moment: toont wat gekozen is en opent de
/// appkiezer. Elk moment heeft zijn eigen keuze.
class MomentAppsSection extends ConsumerStatefulWidget {
  const MomentAppsSection({super.key, required this.kind, this.onChoose});

  final MomentKind kind;

  /// Voor tests: vervangt het openen van de kiezer.
  final Future<void> Function()? onChoose;

  @override
  ConsumerState<MomentAppsSection> createState() => _MomentAppsSectionState();
}

class _MomentAppsSectionState extends ConsumerState<MomentAppsSection> {
  bool _iosChosen = false;

  @override
  void initState() {
    super.initState();
    if (io.Platform.isIOS) _loadIos();
  }

  Future<void> _loadIos() async {
    final blob =
        await ref.read(momentProfileServiceProvider).iosSelection(widget.kind);
    if (mounted) setState(() => _iosChosen = blob != null);
  }

  Future<void> _choose() async {
    if (widget.onChoose != null) return widget.onChoose!();
    final service = ref.read(momentProfileServiceProvider);
    if (io.Platform.isIOS) {
      try {
        await _chooseIos(service);
      } on Object catch (e) {
        _say('Could not save your apps: $e');
      }
      return;
    }
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => MomentAppPickerScreen(kind: widget.kind),
    ));
  }

  void _say(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// De iOS-kiezer is van het systeem en werkt pas na toestemming voor
  /// Screen Time. De selectie komt als opake bytes terug en wordt bij het
  /// profiel van dit moment bewaard.
  Future<void> _chooseIos(MomentProfileService service) async {
    final status =
        await _blockingChannel.invokeMethod<String>('checkAuthorizationStatus');
    if (status != 'approved') {
      await _blockingChannel.invokeMethod<bool>('requestAuthorization');
    }
    final current = await service.iosSelection(widget.kind);
    final result = await _blockingChannel.invokeMethod<Object>(
      'showAppPicker',
      {'returnSelection': true, 'selection': current},
    );
    if (result is! Map) {
      // Een oude build geeft niets terug en bewaart niets per moment.
      _say('Nothing was saved. Stop the app and run it again so the new '
          'picker code is built (a hot reload is not enough).');
      return;
    }
    final blob = result['selection'];
    final total = ((result['apps'] as int?) ?? 0) +
        ((result['categories'] as int?) ?? 0) +
        ((result['websites'] as int?) ?? 0);
    if (blob is! Uint8List || total == 0) {
      await service.clearIosSelection(widget.kind);
      if (mounted) setState(() => _iosChosen = false);
      return;
    }
    await service.saveIosSelection(widget.kind, blob);
    if (mounted) setState(() => _iosChosen = true);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(_momentProfileProvider(widget.kind)).value;
    final count = MomentProfileService.androidAppCount(profile);
    final chosen = io.Platform.isIOS ? _iosChosen : count > 0;
    final summary = !chosen
        ? 'No apps chosen yet.'
        : io.Platform.isIOS
            ? 'Apps chosen.'
            : '$count ${count == 1 ? 'app' : 'apps'} chosen.';
    return MomentSection(
      title: 'Apps to block',
      note: 'Only used for ${widget.kind.profileName}. The other moments keep '
          'their own choice.',
      child: Row(
        children: [
          Expanded(child: Text(summary, style: RestType.sans(15))),
          OutlinedButton(
            onPressed: _choose,
            style: OutlinedButton.styleFrom(
              foregroundColor: RestPalette.primary,
              side: const BorderSide(color: RestPalette.border),
              backgroundColor: RestPalette.background,
              shape: const StadiumBorder(),
              minimumSize: const Size(44, 44),
            ),
            child: Text(
              chosen ? 'Change' : 'Choose apps',
              style: RestType.sans(
                14,
                color: RestPalette.primary,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
