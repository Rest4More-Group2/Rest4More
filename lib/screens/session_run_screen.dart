import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/data/moments/moment_schedule.dart';
import 'package:rest4more/data/moments/session_runner.dart';
import 'package:rest4more/providers/repository_providers.dart';

import 'moments_form_widgets.dart';
import 'moments_widgets.dart';
import 'session_setup_screen.dart';
import 'unblock_flow_screen.dart';
import 'today_screen.dart' show RestPalette, RestType;

enum _Phase { starting, running, ending, finished, failed, releaseFailed }

/// Een lopende sessie met timer (Focus of Reading). Start de blokkade, telt af
/// naar het eindtijdstip en geeft de apps weer vrij. Eerder stoppen vraagt
/// eerst bevestiging en wordt als `stoppedEarly` vastgelegd.
class SessionRunScreen extends ConsumerStatefulWidget {
  const SessionRunScreen({super.key, this.setup, this.resume})
      : assert(setup != null || resume != null);

  /// Een nieuwe sessie starten.
  final FocusSetup? setup;

  /// Een al lopende sessie weer tonen.
  final RunningSession? resume;

  @override
  ConsumerState<SessionRunScreen> createState() => _SessionRunScreenState();
}

class _SessionRunScreenState extends ConsumerState<SessionRunScreen>
    with WidgetsBindingObserver {
  _Phase _phase = _Phase.starting;
  RunningSession? _session;
  String? _error;
  Timer? _ticker;
  bool _endedEarly = false;

  SessionRunner get _runner => ref.read(sessionRunnerProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _begin();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tick();
  }

  Future<void> _begin() async {
    final resume = widget.resume;
    if (resume != null) {
      _run(resume);
      return;
    }
    final setup = widget.setup!;
    try {
      final session = await _runner.start(
        kind: setup.kind.moment,
        minutes: setup.minutes,
        blockProfileId: setup.blockProfileId,
      );
      if (mounted) _run(session);
    } on SessionRunningError catch (e) {
      // Er loopt al een sessie: laat die zien in plaats van hem te vervangen.
      if (mounted) _run(e.running);
    } on SessionStartError {
      _fail('We could not set your apps aside, so nothing was started. '
          'Check that blocking is allowed for Rest For More and try again.');
    } on Object {
      _fail('Something went wrong while starting. Please try again.');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.failed;
      _error = message;
    });
  }

  void _run(RunningSession session) {
    HapticFeedback.lightImpact();
    setState(() {
      _session = session;
      _phase = _Phase.running;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _tick();
  }

  void _tick() {
    final session = _session;
    if (!mounted || session == null || _phase != _Phase.running) return;
    if (session.isOver(DateTime.now())) {
      _finish(early: false);
    } else {
      // iOS: een tijdelijk vrijgegeven blokkade weer dichtzetten als de tijd om is.
      ref.read(unblockServiceProvider).reapplyIfExpired().ignore();
      setState(() {});
    }
  }

  Future<void> _finish({required bool early}) async {
    final session = _session;
    if (session == null || _phase == _Phase.ending) return;
    _ticker?.cancel();
    setState(() => _phase = _Phase.ending);
    _endedEarly = early;
    try {
      await _runner.end(session, early: early);
      if (mounted) setState(() => _phase = _Phase.finished);
    } on ReleaseFailedError {
      if (mounted) setState(() => _phase = _Phase.releaseFailed);
    } on Object {
      _fail('Something went wrong while ending. Please try again.');
    }
  }

  Future<void> _retryRelease() async {
    final session = _session;
    if (session == null) return;
    try {
      await _runner.releaseBlocking(session.kind);
      if (mounted) setState(() => _phase = _Phase.finished);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Your apps are still set aside. Please try again.'),
        ));
      }
    }
  }

  /// Een app tijdelijk vrijgeven, bewust en niet te makkelijk.
  Future<void> _needAnApp() async {
    final session = _session;
    if (session == null || _phase != _Phase.running) return;
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => UnblockFlowScreen(sessionId: session.id),
    ));
  }

  Future<void> _askToStop() async {
    if (_phase != _Phase.running) return;
    if (await confirmStopEarly(context)) await _finish(early: true);
  }

  void _leave() =>
      Navigator.of(context).popUntil((route) => route.isFirst);

  String _clock(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final title = session?.kind.profileName ??
        widget.setup?.kind.title ??
        'Session';
    final iconIndex = switch (session?.kind.name ?? widget.setup?.kind.name) {
      'reading' => 2,
      _ => 1,
    };

    return PopScope(
      canPop: _phase == _Phase.failed ||
          _phase == _Phase.finished ||
          _phase == _Phase.releaseFailed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askToStop();
      },
      child: Scaffold(
        backgroundColor: RestPalette.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                        child: RestMomentIcon(
                          index: iconIndex,
                          color: RestPalette.primary,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(title, style: RestType.serif(44)),
                    const Spacer(),
                    ..._body(session),
                    const Spacer(),
                    ..._actions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _body(RunningSession? session) {
    switch (_phase) {
      case _Phase.starting:
      case _Phase.ending:
        return [
          const Center(
            child: CircularProgressIndicator(color: RestPalette.primary),
          ),
          const SizedBox(height: 20),
          Text(
            _phase == _Phase.starting
                ? 'Setting your apps aside…'
                : 'Bringing your apps back…',
            textAlign: TextAlign.center,
            style: RestType.sans(16, color: RestPalette.accent),
          ),
        ];
      case _Phase.running:
        final left = session!.remaining(DateTime.now());
        final progress = session.total.inSeconds == 0
            ? 1.0
            : 1 - left.inSeconds / session.total.inSeconds;
        return [
          Semantics(
            liveRegion: false,
            label: '${formatDuration(left.inMinutes + (left.inSeconds % 60 > 0 ? 1 : 0))} left',
            child: Text(
              _clock(left),
              textAlign: TextAlign.center,
              style: RestType.serif(72),
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: RestPalette.surface,
              color: RestPalette.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your apps are set aside until ${formatTime(session.endsAt.toLocal())}.',
            textAlign: TextAlign.center,
            style: RestType.sans(16, color: RestPalette.accent),
          ),
          const SizedBox(height: 28),
          Text(
            '“Return gently whenever your attention wanders.”',
            textAlign: TextAlign.center,
            style: RestType.serif(24).copyWith(fontStyle: FontStyle.italic),
          ),
        ];
      case _Phase.finished:
        return [
          Text(
            _endedEarly ? 'Session ended' : 'Well done',
            textAlign: TextAlign.center,
            style: RestType.serif(40),
          ),
          const SizedBox(height: 12),
          Text(
            _endedEarly
                ? 'Your apps are back. That is fine. Begin again whenever '
                    'you like.'
                : 'Your time is complete and your apps are back.',
            textAlign: TextAlign.center,
            style: RestType.sans(16, color: RestPalette.accent),
          ),
        ];
      case _Phase.failed:
        return [
          Text(
            _error ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: RestType.sans(16),
          ),
        ];
      case _Phase.releaseFailed:
        return [
          Text(
            'Your apps are still set aside',
            textAlign: TextAlign.center,
            style: RestType.serif(32),
          ),
          const SizedBox(height: 12),
          Text(
            'The session is over, but we could not bring your apps back. '
            'Try again, or open Help if it keeps happening.',
            textAlign: TextAlign.center,
            style: RestType.sans(16, color: RestPalette.accent),
          ),
        ];
    }
  }

  List<Widget> _actions() {
    switch (_phase) {
      case _Phase.running:
        return [
          TextButton(
            onPressed: _needAnApp,
            style: TextButton.styleFrom(
              foregroundColor: RestPalette.primary,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(
              'Need an app?',
              style: RestType.sans(
                15,
                color: RestPalette.primary,
                weight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _askToStop,
            style: OutlinedButton.styleFrom(
              foregroundColor: RestPalette.primary,
              side: const BorderSide(color: RestPalette.border),
              shape: const StadiumBorder(),
              minimumSize: const Size(double.infinity, 58),
            ),
            child: Text(
              'End early',
              style: RestType.sans(
                17,
                color: RestPalette.primary,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ];
      case _Phase.finished:
      case _Phase.failed:
        return [MomentPrimaryButton(label: 'Done', onPressed: _leave)];
      case _Phase.releaseFailed:
        return [
          MomentPrimaryButton(label: 'Try again', onPressed: _retryRelease),
        ];
      case _Phase.starting:
      case _Phase.ending:
        return const [];
    }
  }
}
