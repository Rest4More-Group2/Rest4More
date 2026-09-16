import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppBlock Prototype',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MyHomePage(title: 'AppBlock Prototype'),
        '/block': (context) => const BlockedScreen(),
        '/picker': (context) => const AppPickerScreen(),
      },
    );
  }
}

class BlockedScreen extends StatelessWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, color: Colors.white, size: 64),
            const SizedBox(height: 16),
            const Text(
              'This app is blocked',
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isBlocked = false;
  static const platform = MethodChannel(
    'com.example.app_blocking_prototype/blocking',
  );

  Future<void> _setBlock() async {
    final newState = !isBlocked;
    try {
      await platform.invokeMethod('setBlocking', {'isBlocking': newState});
      setState(() {
        isBlocked = newState;
      });
    } catch (e) {
      print('MethodChannel error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Block State'),
            Text(
              '$isBlocked',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            OutlinedButton(
              onPressed: _setBlock,
              child: const Icon(Icons.block),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/picker'),
              child: const Text('Choose apps to block'),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final apps = await InstalledApps.getInstalledApps(
      excludeSystemApps: false,
      excludeNonLaunchableApps: true,
      withIcon: true,
    );
    apps.sort((a, b) => a.name.compareTo(b.name));

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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Blocked apps saved')));
      }
    } catch (e) {
      print('MethodChannel error: $e');
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
          : ListView.builder(
              itemCount: _apps.length,
              itemBuilder: (context, index) {
                final app = _apps[index];
                final isSelected = _selectedPackages.contains(app.packageName);

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
