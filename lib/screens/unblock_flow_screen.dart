import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:rest4more/data/moments/moment_schedule.dart';
import 'package:rest4more/data/moments/unblock_service.dart';
import 'package:rest4more/providers/repository_providers.dart';

import 'moment_app_picker_screen.dart';
import 'moments_form_widgets.dart';
import 'today_screen.dart' show RestPalette, RestType;

enum _Step { choose, pause, duration, done }

/// Een app bewust en niet te makkelijk tijdelijk vrijgeven, naar het ontwerp
/// van Opal: kies de app, neem een korte pauze, kies hoe lang je hem echt nodig
/// hebt en bevestig. Na afloop gaat de app vanzelf weer dicht.
///
/// [initialPackage] slaat het kiezen over (de app die je net probeerde te
/// openen). Op iOS is er geen app te kiezen: daar pauzeert de hele blokkade.
class UnblockFlowScreen extends ConsumerStatefulWidget {
  const UnblockFlowScreen({
    super.key,
    this.initialPackage,
    this.sessionId,
    this.loadApps = loadInstalledApps,
    this.pause = UnblockPolicy.pause,
    this.now,
  });

  final String? initialPackage;

  /// De lopende sessie, als er een is. Het vrijgeven wordt daar vastgelegd.
  final String? sessionId;
  final AppLoader loadApps;

  /// Hoe lang de pauze duurt. Alleen tests passen dit aan.
  final Duration pause;
  final DateTime Function()? now;

  @override
  ConsumerState<UnblockFlowScreen> createState() => _UnblockFlowScreenState();
}

class _UnblockFlowScreenState extends ConsumerState<UnblockFlowScreen> {
  late _Step _step;
  List<PickableApp>? _apps;
  bool _loadFailed = false;
  PickableApp? _app;
  int _choice = 1; // index in UnblockPolicy.minutes
  bool _working = false;
  String? _error;
  DateTime? _until;

  UnblockService get _service => ref.read(unblockServiceProvider);
  DateTime get _now => (widget.now ?? DateTime.now)();
  int get _minutes => UnblockPolicy.minutes[_choice];

  @override
  void initState() {
    super.initState();
    _step = _service.choosesApp && widget.initialPackage == null
        ? _Step.choose
        : _Step.pause;
    if (_service.choosesApp) _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      final apps = await _service.blockedApps(widget.loadApps);
      if (!mounted) return;
      setState(() {
        _apps = apps;
        final wanted = widget.initialPackage;
        if (wanted != null) {
          _app = apps.firstWhere(
            (a) => a.id == wanted,
            orElse: () => PickableApp(name: wanted, id: wanted),
          );
        }
      });
    } on Object {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _unblock() async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final until = await _service.grant(package: _app?.id, minutes: _minutes);
      final id = widget.sessionId;
      if (id != null) {
        // Het vrijgeven staat in het logboek van de sessie. Mislukt dat, dan
        // blijft het vrijgeven zelf gewoon staan.
        try {
          await ref.read(sessionRunnerProvider).logUnblock(id, _minutes);
        } on Object {
          // Alleen het logboek.
        }
      }
      HapticFeedback.mediumImpact();
      if (mounted) {
        setState(() {
          _until = until;
          _step = _Step.done;
        });
      }
    } on Object {
      if (mounted) {
        setState(() => _error = 'We could not unblock this right now. '
            'Please try again.');
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _open() async {
    final app = _app;
    if (app != null) {
      try {
        await InstalledApps.startApp(app.id);
      } on Object {
        // De gebruiker kan hem zelf openen.
      }
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: RestPalette.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_step != _Step.done)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          tooltip: 'Cancel and keep it blocked',
                          style: IconButton.styleFrom(
                            backgroundColor: RestPalette.surface,
                            foregroundColor: RestPalette.primary,
                            minimumSize: const Size(44, 44),
                          ),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    Expanded(
                      child: switch (_step) {
                        _Step.choose => _chooseStep(),
                        _Step.pause => _PauseStep(
                            duration: widget.pause,
                            onContinue: () =>
                                setState(() => _step = _Step.duration),
                          ),
                        _Step.duration => _durationStep(),
                        _Step.done => _doneStep(),
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _chooseStep() {
    final apps = _apps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text('Which app do you need?', style: RestType.serif(36)),
        const SizedBox(height: 10),
        Text(
          'Only the one you choose opens, and only for a little while.',
          style: RestType.sans(16, color: RestPalette.accent),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _loadFailed
              ? Center(
                  child: Text('Could not read your blocked apps.',
                      style: RestType.sans(16)))
              : apps == null
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: RestPalette.primary))
                  : apps.isEmpty
                      ? Center(
                          child: Text('Nothing is blocked right now.',
                              style: RestType.sans(16)))
                      : ListView(
                          children: [
                            for (final app in apps)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: app.icon != null
                                    ? Image.memory(app.icon!,
                                        width: 36, height: 36)
                                    : const Icon(Icons.apps,
                                        color: RestPalette.primary),
                                title: Text(app.name,
                                    style: RestType.sans(16,
                                        weight: FontWeight.w600)),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => setState(() {
                                  _app = app;
                                  _step = _Step.pause;
                                }),
                              ),
                          ],
                        ),
        ),
      ],
    );
  }

  Widget _durationStep() {
    final until = _now.add(Duration(minutes: _minutes));
    final name = _app?.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text('How long do you really need?', style: RestType.serif(36)),
        const SizedBox(height: 24),
        Expanded(
          child: Row(
            children: [
              // Verticale schuif: omhoog is langer.
              SizedBox(
                width: 72,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Semantics(
                    label: 'Minutes to unblock',
                    value: '$_minutes minutes',
                    child: Slider(
                      value: _choice.toDouble(),
                      min: 0,
                      max: (UnblockPolicy.minutes.length - 1).toDouble(),
                      divisions: UnblockPolicy.minutes.length - 1,
                      label: '$_minutes min',
                      activeColor: RestPalette.primary,
                      inactiveColor: RestPalette.surface,
                      onChanged: (v) {
                        if (v.round() != _choice) {
                          HapticFeedback.selectionClick();
                          setState(() => _choice = v.round());
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_minutes', style: RestType.serif(120)),
                    Text(_minutes == 1 ? 'minute' : 'minutes',
                        style: RestType.sans(20, color: RestPalette.accent)),
                    const SizedBox(height: 20),
                    Text(
                      name == null
                          ? 'Your apps will be available until '
                              '${formatTime(until)}.'
                          : '$name will be available until '
                              '${formatTime(until)}.',
                      style: RestType.sans(16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          Text(_error!, style: RestType.sans(14, color: RestPalette.accent)),
          const SizedBox(height: 12),
        ],
        FilledButton(
          onPressed: _working ? null : _unblock,
          style: FilledButton.styleFrom(
            backgroundColor: RestPalette.gold,
            foregroundColor: RestPalette.ink,
            disabledBackgroundColor: RestPalette.surface,
            elevation: 0,
            shape: const StadiumBorder(),
            minimumSize: const Size(double.infinity, 58),
          ),
          child: Text(
            _working ? 'Unblocking…' : 'Unblock',
            style: RestType.sans(17,
                color: RestPalette.ink, weight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _doneStep() {
    final until = _until!;
    final name = _app?.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Text('Unblocked', textAlign: TextAlign.center,
            style: RestType.serif(44)),
        const SizedBox(height: 12),
        Text(
          '${name ?? 'Your apps'} ${name == null ? 'are' : 'is'} available '
          'until ${formatTime(until)}. It locks again by itself.',
          textAlign: TextAlign.center,
          style: RestType.sans(16, color: RestPalette.accent),
        ),
        const Spacer(),
        MomentPrimaryButton(
          label: _app != null ? 'Open ${_app!.name}' : 'Done',
          onPressed: _open,
        ),
        if (_app != null)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not now'),
          ),
      ],
    );
  }
}

/// De pauze: een balk die langzaam vol loopt. Er is niets om te doen en niets
/// over te slaan; pas daarna verschijnt "Continue". Het aftellen is bewust niet
/// in beeld, dat maakt onrustig.
class _PauseStep extends StatefulWidget {
  const _PauseStep({required this.duration, required this.onContinue});

  final Duration duration;
  final VoidCallback onContinue;

  @override
  State<_PauseStep> createState() => _PauseStepState();
}

class _PauseStepState extends State<_PauseStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            HapticFeedback.lightImpact();
            setState(() => _ready = true);
            SemanticsService.sendAnnouncement(
              View.of(context),
              'You can continue now.',
              TextDirection.ltr,
            );
          }
        })
        ..forward();
  bool _ready = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wie minder beweging wil, ziet de balk in stappen in plaats van glijdend.
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Semantics(
          liveRegion: true,
          child: Text(
            'Take a moment to breathe',
            textAlign: TextAlign.center,
            style: RestType.serif(40),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _ready
              ? 'Whenever you are ready.'
              : 'Is this something you need, or something you reached for?',
          textAlign: TextAlign.center,
          style: RestType.sans(16, color: RestPalette.accent),
        ),
        const SizedBox(height: 40),
        Semantics(
          label: _ready
              ? 'Pause finished'
              : 'Pause in progress, a few seconds',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => LinearProgressIndicator(
                value: reduceMotion
                    ? (_controller.value * 5).floor() / 5
                    : _controller.value,
                minHeight: 8,
                backgroundColor: RestPalette.surface,
                color: RestPalette.primary,
              ),
            ),
          ),
        ),
        const Spacer(),
        AnimatedOpacity(
          opacity: _ready ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: IgnorePointer(
            ignoring: !_ready,
            child: ExcludeSemantics(
              excluding: !_ready,
              child: MomentPrimaryButton(
                label: 'Continue',
                onPressed: widget.onContinue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
