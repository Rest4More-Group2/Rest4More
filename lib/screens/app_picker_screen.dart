import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    List<AppInfo> apps = [];
    if (io.Platform.isAndroid) {
      apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        excludeNonLaunchableApps: true,
        withIcon: true,
      );
      apps.sort((a, b) => a.name.compareTo(b.name));
    }

    final result = await platform.invokeMethod('getBlockedPackages');
    final savedPackages = (result as List<dynamic>).cast<String>().toSet();

    setState(() {
      _apps = apps;
      _selectedPackages = savedPackages;
      _isLoading = false;
    });
  }

  void _toggleApp(String packageName, bool? checked) {
    setState(() {
      if (checked == true) {
        _selectedPackages.add(packageName);
      } else {
        _selectedPackages.remove(packageName);
      }
    });
  }

  Future<void> _saveSelection() async {
    try {
      await platform.invokeMethod('setBlockedPackages', {
        'blockedPackages': _selectedPackages.toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Blocked apps saved')));
      }
    } catch (e) {
      debugPrint('MethodChannel error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select apps to block'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveSelection),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !io.Platform.isAndroid
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'App selection is only available on Android for now.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              itemCount: _apps.length,
              itemBuilder: (context, index) {
                final app = _apps[index];
                final isSelected = _selectedPackages.contains(
                  app.packageName,
                );

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (checked) => _toggleApp(app.packageName, checked),
                  title: Text(app.name),
                  subtitle: Text(app.packageName),
                  secondary: app.icon != null
                      ? Image.memory(app.icon!, width: 40, height: 40)
                      : const Icon(Icons.android),
                );
              },
            ),
    );
  }
}