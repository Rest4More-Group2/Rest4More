import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:rest4more/data/moments/moment_profiles.dart';
import 'package:rest4more/providers/repository_providers.dart';

import 'moments_form_widgets.dart';
import 'today_screen.dart' show RestPalette, RestType;

/// Een app die gekozen kan worden.
class PickableApp {
  const PickableApp({required this.name, required this.id, this.icon});

  final String name;

  /// Android: de pakketnaam.
  final String id;
  final Uint8List? icon;
}

typedef AppLoader = Future<List<PickableApp>> Function();

/// Leest de geïnstalleerde apps van dit toestel (Android).
Future<List<PickableApp>> loadInstalledApps() async {
  final apps = await InstalledApps.getInstalledApps(
    excludeSystemApps: false,
    excludeNonLaunchableApps: true,
    withIcon: true,
  );
  apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return [
    for (final a in apps)
      PickableApp(name: a.name, id: a.packageName, icon: a.icon),
  ];
}

/// Appkiezer voor één moment (Android). De keuze wordt bewaard in het
/// blokkeerprofiel van dat moment, los van de andere momenten.
class MomentAppPickerScreen extends ConsumerStatefulWidget {
  const MomentAppPickerScreen({
    super.key,
    required this.kind,
    this.loadApps = loadInstalledApps,
  });

  final MomentKind kind;
  final AppLoader loadApps;

  @override
  ConsumerState<MomentAppPickerScreen> createState() =>
      _MomentAppPickerScreenState();
}

class _MomentAppPickerScreenState extends ConsumerState<MomentAppPickerScreen> {
  List<PickableApp> _apps = const [];
  Set<String> _selected = {};
  String _query = '';
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final service = ref.read(momentProfileServiceProvider);
      final profile = await service.ensure(widget.kind);
      final apps = await widget.loadApps();
      if (!mounted) return;
      setState(() {
        _apps = apps;
        _selected = MomentProfileService.androidPackages(profile);
        _loading = false;
      });
    } on Object {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    await ref
        .read(momentProfileServiceProvider)
        .saveAndroidPackages(widget.kind, _selected);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final visible = [
      for (final a in _apps)
        if (a.name.toLowerCase().contains(_query.toLowerCase())) a,
    ];
    return Scaffold(
      backgroundColor: RestPalette.background,
      appBar: AppBar(
        backgroundColor: RestPalette.background,
        foregroundColor: RestPalette.primary,
        elevation: 0,
        title: Text(
          'Apps for ${widget.kind.profileName}',
          style: RestType.serif(26),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: MomentPrimaryButton(
            label: _selected.isEmpty
                ? 'Save'
                : 'Save · ${_selected.length} selected',
            onPressed: _loading ? null : _save,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: RestPalette.primary),
            )
          : _failed
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Could not read your apps.',
                        style: RestType.sans(16),
                      ),
                      TextButton(onPressed: _load, child: const Text('Try again')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: 'Search apps',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: RestPalette.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(100),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (context, i) {
                          final app = visible[i];
                          return CheckboxListTile(
                            value: _selected.contains(app.id),
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _selected = {..._selected, app.id};
                              } else {
                                _selected = {..._selected}..remove(app.id);
                              }
                            }),
                            activeColor: RestPalette.primary,
                            checkColor: RestPalette.background,
                            controlAffinity: ListTileControlAffinity.trailing,
                            secondary: app.icon != null
                                ? Image.memory(app.icon!, width: 36, height: 36)
                                : const Icon(Icons.apps,
                                    color: RestPalette.primary),
                            title: Text(app.name, style: RestType.sans(15)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
