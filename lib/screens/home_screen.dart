import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rest4more/data/tags/tag_service.dart';
import 'app_selection.dart';
import 'today_screen.dart' show RestPalette, RestType;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  bool isBlocked = false;
  bool _busy = false;
  bool _loading = false;
  bool _statusKnown = false;
  StreamSubscription<bool>? _tagSub;
  static const platform = MethodChannel(
    'com.example.app_blocking_prototype/blocking',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tagSub = TagService.blockingChanges.listen((blocking) {
      if (!mounted) return;
      setState(() {
        isBlocked = blocking;
        _statusKnown = true;
      });
    });
    _loadBlockState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tagSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadBlockState();
  }

  Future<void> _loadBlockState() async {
    if (kIsWeb) return;
    setState(() => _loading = true);
    try {
      final blocked = await platform.invokeMethod<bool>('getBlocking');
      if (!mounted) return;
      setState(() {
        isBlocked = blocked ?? false;
        _statusKnown = blocked != null;
      });
    } catch (e) {
      debugPrint('MethodChannel error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setBlock() async {
    if (_busy || _loading) return;
    if (kIsWeb) {
      _showError('App blocking is available on the mobile app.');
      return;
    }
    final newState = !isBlocked;
    setState(() => _busy = true);
    try {
      await platform.invokeMethod('setBlocking', {'isBlocking': newState});
      if (!mounted) return;
      setState(() {
        isBlocked = newState;
        _statusKnown = true;
      });
    } catch (e) {
      debugPrint('MethodChannel error: $e');
      _showError('Could not update app blocking. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scanNfcTag() async {
    if (_busy || _loading) return;
    if (kIsWeb) {
      _showError('NFC scanning is available on the mobile app.');
      return;
    }
    setState(() => _busy = true);
    try {
      final newState = await Navigator.pushNamed(
        context, '/nfcScan', arguments: isBlocked,
      );
      if (mounted && newState is bool) {
        setState(() {
          isBlocked = newState;
          _statusKnown = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPairedTags() async {
    if (kIsWeb) {
      _showError('Paired tags are available on the mobile app.');
      return;
    }
    await Navigator.pushNamed(context, '/pairedTags');
  }

  Future<void> _chooseApps() async {
    if (kIsWeb) {
      _showError('Choose apps to block on the mobile app.');
      return;
    }
    await openAppSelection(context);
    if (mounted) await _loadBlockState();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _busy || _loading;
    final status = _loading ? 'Checking status'
      : !_statusKnown ? 'Status not checked'
      : isBlocked ? 'Blocking is on' : 'Blocking is off';

    return Scaffold(
      backgroundColor: RestPalette.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Back to Focus'),
                      style: TextButton.styleFrom(
                        foregroundColor: RestPalette.primary,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 48),
                        textStyle: RestType.sans(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 56, height: 56,
                      decoration: const BoxDecoration(
                        color: RestPalette.surface, shape: BoxShape.circle),
                      child: const Icon(Icons.shield_outlined,
                        color: RestPalette.primary, size: 28),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Make room for focus', style: RestType.serif(40)),
                  const SizedBox(height: 12),
                  Text('Choose the apps you want to put aside, then turn on blocking '
                    'or use your NFC tag.',
                    style: RestType.sans(16, color: RestPalette.accent)),
                  const SizedBox(height: 28),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: RestPalette.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(width: 2,
                        color: _statusKnown && isBlocked
                          ? RestPalette.primary : Colors.transparent),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('APP BLOCKING', style: RestType.sans(11,
                          color: RestPalette.accent, weight: FontWeight.w600)),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(child: Text(status, style: RestType.serif(28))),
                          if (disabled)
                            const SizedBox.square(dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2,
                                color: RestPalette.primary))
                          else Icon(_statusKnown && isBlocked
                            ? Icons.shield : Icons.shield_outlined,
                            color: RestPalette.primary, size: 26),
                        ]),
                        const SizedBox(height: 12),
                        Text(!_statusKnown
                          ? 'Choose your apps before enabling blocking.'
                          : isBlocked
                            ? 'You can turn blocking off here or scan your NFC tag.'
                            : 'Ready when you are. Enable blocking to put your selected apps aside.',
                          style: RestType.sans(14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _button(
                    label: isBlocked ? 'Turn blocking off' : 'Turn blocking on',
                    icon: isBlocked ? Icons.lock_open : Icons.lock_outline,
                    onPressed: disabled ? null : _setBlock,
                  ),
                  const SizedBox(height: 14),
                  _button(label: 'Choose apps to block', icon: Icons.apps_outlined,
                    onPressed: disabled ? null : _chooseApps, outlined: true),
                  const SizedBox(height: 14),
                  _button(label: 'Scan NFC tag', icon: Icons.nfc,
                    onPressed: disabled ? null : _scanNfcTag, outlined: true),
                  const SizedBox(height: 14),
                  _button(label: 'Paired tags', icon: Icons.sell_outlined,
                    onPressed: disabled ? null : _openPairedTags, outlined: true),
                  const SizedBox(height: 24),
                  Text('A little space. One thing at a time.',
                    textAlign: TextAlign.center,
                    style: RestType.serif(22).copyWith(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _button({required String label, required IconData icon,
    required VoidCallback? onPressed, bool outlined = false}) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 56)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 22, vertical: 15)),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      foregroundColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.disabled) ? RestPalette.accent
          : outlined ? RestPalette.primary : RestPalette.background),
      backgroundColor: WidgetStateProperty.resolveWith((states) =>
        outlined ? Colors.transparent
          : states.contains(WidgetState.disabled)
            ? RestPalette.surface : RestPalette.primary),
      side: WidgetStatePropertyAll(outlined
        ? const BorderSide(color: RestPalette.primary) : BorderSide.none),
      textStyle: WidgetStatePropertyAll(RestType.sans(15, weight: FontWeight.w600)),
      elevation: const WidgetStatePropertyAll(0),
    );
    final child = Row(children: [
      Icon(icon, size: 22), const SizedBox(width: 12),
      Expanded(child: Text(label)),
      const Icon(Icons.chevron_right, size: 22),
    ]);
    return outlined
      ? OutlinedButton(onPressed: onPressed, style: style, child: child)
      : FilledButton(onPressed: onPressed, style: style, child: child);
  }
}
