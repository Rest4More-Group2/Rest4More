import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';

import 'today_screen.dart' show RestPalette, RestType;

class AppPickerScreen extends StatefulWidget {
  const AppPickerScreen({super.key});

  @override
  State<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends State<AppPickerScreen> {
  static const platform = MethodChannel(
    'com.example.app_blocking_prototype/blocking',
  );

  List<AppInfo> _apps = [];
  Set<String> _selectedPackages = {};
  bool _isLoading = true;
  bool _saving = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    List<AppInfo> apps = [];
    Set<String> saved = {};
    try {
      if (io.Platform.isAndroid) {
        apps = await InstalledApps.getInstalledApps(
          excludeSystemApps: false,
          excludeNonLaunchableApps: true,
          withIcon: true,
        );
        apps.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      }
      final result = await platform.invokeMethod('getBlockedPackages');
      saved = (result as List<dynamic>).cast<String>().toSet();
    } catch (e) {
      debugPrint('App picker error: $e');
    }
    if (!mounted) return;
    setState(() {
      _apps = apps;
      _selectedPackages = saved;
      _isLoading = false;
    });
  }

  void _toggleApp(String packageName) {
    setState(() {
      if (!_selectedPackages.add(packageName)) {
        _selectedPackages.remove(packageName);
      }
    });
  }

  Future<void> _saveSelection() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await platform.invokeMethod('setBlockedPackages', {
        'blockedPackages': _selectedPackages.toList(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('MethodChannel error: $e');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save your apps. Try again.')),
        );
      }
    }
  }

  List<AppInfo> get _visibleApps {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _apps;
    return _apps.where((a) => a.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final count = _selectedPackages.length;
    final apps = _visibleApps;

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
                onPressed: _isLoading || _saving ? null : _saveSelection,
                style: FilledButton.styleFrom(
                  backgroundColor: RestPalette.primary,
                  foregroundColor: RestPalette.background,
                  disabledBackgroundColor: RestPalette.surface,
                  disabledForegroundColor: RestPalette.accent,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  minimumSize: const Size(double.infinity, 58),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 16,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      count == 0 ? 'Save' : 'Save $count '
                          '${count == 1 ? 'app' : 'apps'}',
                      style: RestType.sans(17, weight: FontWeight.w600,
                          color: _isLoading || _saving
                              ? RestPalette.accent : RestPalette.background),
                    ),
                    const Spacer(),
                    const Icon(Icons.check, size: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 20),
                      Text('Choose apps', style: RestType.serif(40)),
                      const SizedBox(height: 8),
                      Text(
                        count == 0
                            ? 'Pick the apps you want to set aside.'
                            : '$count ${count == 1 ? 'app' : 'apps'} '
                                'will be set aside.',
                        style: RestType.sans(16, color: RestPalette.accent),
                      ),
                      const SizedBox(height: 18),
                      if (io.Platform.isAndroid) _searchField(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                Expanded(child: _body(apps)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchField() => TextField(
    onChanged: (value) => setState(() => _query = value),
    style: RestType.sans(15),
    cursorColor: RestPalette.primary,
    decoration: InputDecoration(
      hintText: 'Search apps',
      hintStyle: RestType.sans(15, color: RestPalette.accent),
      prefixIcon: const Icon(Icons.search, color: RestPalette.accent),
      filled: true,
      fillColor: RestPalette.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: BorderSide.none,
      ),
    ),
  );

  Widget _body(List<AppInfo> apps) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: RestPalette.primary),
      );
    }
    if (!io.Platform.isAndroid) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Choosing apps from this list is only available on Android.',
          style: RestType.sans(15, color: RestPalette.accent),
        ),
      );
    }
    if (apps.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text('No apps found.',
            style: RestType.sans(15, color: RestPalette.accent)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      itemCount: apps.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final app = apps[index];
        final selected = _selectedPackages.contains(app.packageName);
        return _appRow(app, selected);
      },
    );
  }

  Widget _appRow(AppInfo app, bool selected) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    decoration: BoxDecoration(
      color: RestPalette.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        width: 2,
        color: selected ? RestPalette.primary : Colors.transparent,
      ),
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _toggleApp(app.packageName),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: app.icon != null
                    ? Image.memory(app.icon!, width: 40, height: 40)
                    : const SizedBox.square(
                        dimension: 40,
                        child: Icon(Icons.apps, color: RestPalette.primary),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  app.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RestType.sans(15, weight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? RestPalette.primary : Colors.transparent,
                  border: Border.all(
                    width: 1.6,
                    color: selected ? RestPalette.primary : RestPalette.accent,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 16,
                        color: RestPalette.background)
                    : null,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
