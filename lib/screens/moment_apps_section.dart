import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/data/database/app_database.dart';
import 'package:rest4more/data/moments/moment_profiles.dart';
import 'package:rest4more/data/moments/tag_selection_sync.dart';
import 'package:rest4more/providers/repository_providers.dart';

import 'accessibility_access_screen.dart';
import 'moment_app_picker_screen.dart';
import 'moments_form_widgets.dart';
import 'today_screen.dart' show RestPalette, RestType;

final _momentProfileProvider =
    StreamProvider.autoDispose.family<BlockProfile?, MomentKind>(
  (ref, kind) => ref.watch(momentProfileServiceProvider).watch(kind),
);

const MethodChannel _blockingChannel =
    MethodChannel('com.example.app_blocking_prototype/blocking');

/// Uitkomst van [chooseMomentApps].
enum AppsChoice {
  /// Er is (op iOS) een keuze bewaard.
  chosen,

  /// Er is (op iOS) niets gekozen; de oude keuze is gewist.
  cleared,

  /// Niets veranderd, of de keuze is op een eigen scherm gemaakt (Android).
  unchanged,
}

/// Laat de gebruiker de apps van [kind] kiezen en bewaart die bij het profiel
/// van dat moment. Gedeeld door de sectie op elke pagina en door het
/// Tag-scherm. [onMessage] krijgt een tekst voor de gebruiker als er iets
/// misgaat.
Future<AppsChoice> chooseMomentApps(
  BuildContext context,
  MomentProfileService service,
  MomentKind kind, {
  required void Function(String) onMessage,
}) async {
  try {
    final AppsChoice outcome;
    if (io.Platform.isIOS) {
      outcome = await _chooseIos(service, kind, onMessage);
    } else {
      outcome = await _chooseAndroid(context, kind);
    }
    // Het Tag-moment moet zijn keuze ook op het toestel hebben, voor tags die
    // de blokkade starten terwijl de app dicht is.
    if (kind == MomentKind.tag) await TagSelectionSync(service).mirror();
    return outcome;
  } on Object catch (e) {
    onMessage('Could not save your apps: $e');
    return AppsChoice.unchanged;
  }
}

Future<AppsChoice> _chooseAndroid(BuildContext context, MomentKind kind) async {
  // Blokkeren werkt via de toegankelijkheidsservice: vraag daar eerst om.
  var enabled = true;
  try {
    enabled = await _blockingChannel.invokeMethod<bool>('isAccessibilityEnabled') ??
        true;
  } on Object {
    // Niet te controleren: ga door naar de kiezer.
  }
  if (!context.mounted) return AppsChoice.unchanged;
  final picker = MomentAppPickerScreen(kind: kind);
  await Navigator.of(context).push<void>(MaterialPageRoute<void>(
    builder: (_) =>
        enabled ? picker : AccessibilityAccessScreen(next: (_) => picker),
  ));
  return AppsChoice.unchanged;
}

/// De iOS-kiezer is van het systeem en werkt pas na toestemming voor Screen
/// Time. De selectie komt als opake bytes terug en wordt bij het profiel van
/// dit moment bewaard.
Future<AppsChoice> _chooseIos(
  MomentProfileService service,
  MomentKind kind,
  void Function(String) onMessage,
) async {
  final status =
      await _blockingChannel.invokeMethod<String>('checkAuthorizationStatus');
  if (status != 'approved') {
    await _blockingChannel.invokeMethod<bool>('requestAuthorization');
  }
  final current = await service.iosSelection(kind);
  final result = await _blockingChannel.invokeMethod<Object>(
    'showAppPicker',
    {'returnSelection': true, 'selection': current},
  );
  if (result is! Map) {
    // Een oude build geeft niets terug en bewaart niets per moment.
    onMessage('Nothing was saved. Stop the app and run it again so the new '
        'picker code is built (a hot reload is not enough).');
    return AppsChoice.unchanged;
  }
  final blob = result['selection'];
  final total = ((result['apps'] as int?) ?? 0) +
      ((result['categories'] as int?) ?? 0) +
      ((result['websites'] as int?) ?? 0);
  if (blob is! Uint8List || total == 0) {
    await service.clearIosSelection(kind);
    return AppsChoice.cleared;
  }
  await service.saveIosSelection(kind, blob);
  return AppsChoice.chosen;
}

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
    final outcome = await chooseMomentApps(
      context,
      ref.read(momentProfileServiceProvider),
      widget.kind,
      onMessage: _say,
    );
    if (!mounted) return;
    if (outcome == AppsChoice.chosen) setState(() => _iosChosen = true);
    if (outcome == AppsChoice.cleared) setState(() => _iosChosen = false);
  }

  void _say(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
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
