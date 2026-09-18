import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  @override
  void initState() {
    super.initState();
    _loadBlockState();
  }

  Future<void> _loadBlockState() async {
    if (!io.Platform.isAndroid) return;
    try {
      final blocked = await platform.invokeMethod<bool>('getBlocking');
      if (mounted) setState(() => isBlocked = blocked ?? false);
    } catch (e) {
      debugPrint('MethodChannel error: $e');
    }
  }

  Future<void> _setBlock() async {
    final newState = !isBlocked;
    try {
      await platform.invokeMethod('setBlocking', {'isBlocking': newState});
      setState(() {
        isBlocked = newState;
      });
    } catch (e) {
      debugPrint('MethodChannel error: $e');
    }
  }

  Future<void> _scanNfcTag() async {
    final newState = await Navigator.pushNamed(
      context,
      '/nfcScan',
      arguments: isBlocked,
    );
    if (mounted && newState is bool) {
      setState(() {
        isBlocked = newState;
      });
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
            if (io.Platform.isAndroid) ...[
              OutlinedButton.icon(
                onPressed: _scanNfcTag,
                icon: const Icon(Icons.nfc),
                label: const Text('Block/unblock with NFC tag'),
              ),
              const SizedBox(height: 16),
            ],
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                io.Platform.isAndroid ? '/picker' : '/authorizationIOS',
              ),
              child: const Text('Choose apps to block'),
            ),
          ],
        ),
      ),
    );
  }
}