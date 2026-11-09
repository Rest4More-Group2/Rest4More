import 'package:rest4more/l10n/format.dart';
import 'package:rest4more/l10n/app_localizations.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/data/moments/moment_schedule.dart';
import 'package:rest4more/data/moments/moment_profiles.dart';
import 'package:rest4more/data/moments/session_runner.dart';
import 'package:rest4more/providers/notification_providers.dart';
import 'package:rest4more/providers/repository_providers.dart';

import 'end_early_screen.dart';
import 'moments_form_widgets.dart';
import 'moments_widgets.dart';
import 'session_setup_screen.dart';
import 'unblock_flow_screen.dart';
import 'unblocked_screen.dart';
import 'today_screen.dart' show RestPalette, RestType;
import 'unblock_flow_screen.dart';

enum _Phase {
  starting,
  running,
  overtime,
  ending,
  finished,
  failed,
  releaseFailed,
}

/// A timed Focus or Reading session. Apps stay blocked after the planned
/// duration until the user ends the session.
class SessionRunScreen extends ConsumerStatefulWidget {
  const SessionRunScreen({
    super.key,
    this.setup,
    this.resume,
    this.manualKind,
    this.manualMinutes,
  }) : assert(setup != null || resume != null || manualKind != null);

  /// A new session to start.
  final FocusSetup? setup;

  /// An already-running session to show again.
  final RunningSession? resume;

  /// A manually started Morning or Evening uses its saved steps duration.
  final MomentKind? manualKind;
  final int? manualMinutes;

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
  bool _askingToStop = false;
  StreamSubscription<RunningSession?>? _watch;

  /// Of het vrijgeven of [UnblockedScreen] er nu bovenop ligt.
  bool _unblockOpen = false;
  bool _wasPaused = false;

  /// "Focus resumed · paused for N min", even na een pauze.
  String? _notice;
  Timer? _noticeTimer;

  /// Lets _finish wait for scheduling to complete before cancelling the
  /// notification, so an early finish cannot race with a pending schedule.
  Future<void> _notificationWork = Future<void>.value();

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
    _noticeTimer?.cancel();
    _watch?.cancel();
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
    final setup = widget.setup;
    try {
      final kind = widget.manualKind ?? setup!.kind.moment;
      final profile = widget.manualKind == null
          ? null
          : await ref.read(momentProfileServiceProvider).ensure(kind);
      final session = await _runner.start(
        kind: kind,
        minutes: widget.manualMinutes ?? setup!.minutes,
        blockProfileId: profile?.id ?? setup?.blockProfileId,
      );
      if (mounted) _run(session);
    } on SessionRunningError catch (e) {
      // Show the existing session instead of replacing it.
      if (mounted) _run(e.running);
    } on SessionStartError {
      _fail(
        'We could not set your apps aside, so nothing was started. '
        'Check that blocking is allowed for Rest For More and try again.',
      );
    } on Object {
      if (!mounted) return;
      _fail(AppLocalizations.of(context).sessionStartFailed);
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
    _notificationWork = _scheduleSessionEndNotification(session);
    _tick();
  }

  Future<void> _scheduleSessionEndNotification(
  RunningSession session,
) async {
  try {
    await ref.read(reminderSchedulerProvider).scheduleSessionEnd(
          sessionId: session.id,
          sessionName: session.kind.profileName,
          endsAt: session.endsAt,
        );

    debugPrint(
      '[session-notification] scheduled '
      'session=${session.id} endsAt=${session.endsAt}',
    );
  } on Object catch (error, stackTrace) {
    debugPrint(
      '[session-notification] scheduling failed: $error\n$stackTrace',
    );
  }
}

  void _tick() {
    final session = _session;
    if (!mounted || session == null) return;

    if (_phase == _Phase.overtime) {
      // Keep the overtime display updating and reapply an expired app unblock.
    if (!mounted || session == null || _phase != _Phase.running) return;
    final now = DateTime.now();
    final paused = session.isPaused(now);
    if (_wasPaused && !paused) _showResumed(session, now);
    _wasPaused = paused;
    if (session.isOver(now)) {
      _finish(early: false);
    } else if (paused &&
        !_unblockOpen &&
        (ModalRoute.of(context)?.isCurrent ?? false)) {
      // Na een herstart midden in een pauze: het juiste scherm terug.
      _showUnblocked(session, session.activePause(now)!);
    } else {
      // iOS: een tijdelijk vrijgegeven blokkade weer dichtzetten als de tijd om is.
      ref.read(unblockServiceProvider).reapplyIfExpired().ignore();
      setState(() {});
      return;
    }

    if (_phase != _Phase.running) return;

    if (session.isOver(DateTime.now())) {
      // Keep the ticker running. The user ends the session manually.
      setState(() => _phase = _Phase.overtime);
      return;
    }

    ref.read(unblockServiceProvider).reapplyIfExpired().ignore();
    setState(() {});
  }

  Future<void> _finish({required bool early}) async {
    final l10n = AppLocalizations.of(context);
    final session = _session;
    if (session == null || _phase == _Phase.ending) return;

    _ticker?.cancel();
    setState(() => _phase = _Phase.ending);
    _endedEarly = early;

    // Wait for any start-time schedule to finish, then cancel it. Notification
    // errors must not prevent the session from ending.
    try {
      await _notificationWork;
    } on Object {
      // Continue ending the session.
    }

    try {
      await ref.read(reminderSchedulerProvider).cancelSessionEnd();
    } on Object {
      // Continue ending the session.
    }

    try {
      await _runner.end(session, early: early);
      if (mounted) setState(() => _phase = _Phase.finished);
    } on ReleaseFailedError {
      if (mounted) setState(() => _phase = _Phase.releaseFailed);
    } on Object {
      _fail(l10n.sessionEndFailed);
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your apps are still set aside. Please try again.'),
          ),
        );
      }
    }
  }

  /// Temporarily release an app through the deliberate unblock flow.
  Future<void> _needAnApp() async {
    final session = _session;
    if (session == null || _phase != _Phase.running) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => UnblockFlowScreen(sessionId: session.id),
      ),
    );
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).appsStillSetAsideTryAgain),
        ));
      }
    }
  }

  /// Een app tijdelijk vrijgeven, bewust en niet te makkelijk. De timer
  /// staat pas stil vanaf "Unblock", niet tijdens de pauze ervoor.
  Future<void> _needAnApp() async {
    final session = _session;
    if (session == null || _phase != _Phase.running || _unblockOpen) return;
    _unblockOpen = true;
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => const UnblockFlowScreen(),
    ));
    await _afterUnblock(session);
  }

  Future<void> _showUnblocked(RunningSession session, SessionPause pause) async {
    _unblockOpen = true;
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => UnblockedScreen(
        until: pause.until,
        granted: pause.until.difference(pause.start),
        session: session,
      ),
    ));
    await _afterUnblock(session);
  }

  /// Terug van het vrijgeven: eerst de nieuwe stand uit het logboek, anders
  /// lijkt de oude stand nog gepauzeerd en gaat het scherm opnieuw open.
  Future<void> _afterUnblock(RunningSession session) async {
    try {
      final fresh = await _runner.current();
      if (fresh != null && fresh.id == session.id) _session = fresh;
    } on Object {
      // De stroom van het logboek komt er ook nog mee.
    }
    _unblockOpen = false;
    _tick();
  }

  /// De laatste pauze is net voorbij: zeg even hoe lang die duurde.
  void _showResumed(RunningSession session, DateTime now) {
    SessionPause? last;
    for (final p in session.pauses) {
      if (!p.end.isAfter(now) && (last == null || p.end.isAfter(last.end))) {
        last = p;
      }
    }
    if (last == null) return;
    final seconds = last.length.inSeconds;
    final notice = seconds < 60
        ? 'Focus resumed · paused for under a minute'
        : 'Focus resumed · paused for '
            '${formatDuration((seconds / 60).round())}';
    _noticeTimer?.cancel();
    setState(() => _notice = notice);
    _noticeTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _notice = null);
    });
  }

  /// Eerder stoppen gaat via een korte pauze. De timer hier loopt intussen
  /// gewoon door, dus "Keep going" pakt hem zonder gat weer op.
  Future<void> _askToStop() async {
    if (_phase != _Phase.running || _askingToStop) return;
    _askingToStop = true;
    final end = await Navigator.of(context).push<bool>(MaterialPageRoute<bool>(
      builder: (_) => const EndEarlyScreen(),
    ));
    _askingToStop = false;
    // De sessie kan intussen vanzelf afgelopen zijn.
    if (end == true && mounted && _phase == _Phase.running) {
      await _finish(early: true);
    }
  }

  void _leave() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String _clock(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final title =
        session?.kind.profileName ?? widget.setup?.kind.title ?? 'Session';
    final iconIndex = switch (session?.kind.name ?? widget.setup?.kind.name) {
  @override
  Widget build(BuildContext context) {
    final session = _session;
    final l10n = AppLocalizations.of(context);
    final title = session?.kind.profileName ??
        widget.setup?.kind.title(l10n) ??
        widget.manualKind?.profileName ??
        l10n.sessionTitle;
    final iconIndex = switch (session?.kind.name ??
        widget.manualKind?.name ??
        widget.setup?.kind.name) {
      'reading' => 2,
      'morning' => 0,
      'evening' => 3,
      _ => 1,
    };

    return PopScope(
      canPop: _phase == _Phase.overtime ||
          _phase == _Phase.failed ||
          _phase == _Phase.finished ||
          _phase == _Phase.releaseFailed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askToStop();
      },
      child: Scaffold(
        backgroundColor: RestPalette.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                ? AppLocalizations.of(context).settingAppsAside
                : AppLocalizations.of(context).bringingAppsBack,
            textAlign: TextAlign.center,
            style: RestType.sans(16, color: RestPalette.accent),
          ),
        ];

      case _Phase.running:
      case _Phase.overtime:
        final activeSession = session!;
        final isOvertime = _phase == _Phase.overtime;
        final now = DateTime.now();
        final remaining = activeSession.remaining(now);
        final overtime = now.difference(activeSession.endsAt);
        final displayedTime = isOvertime ? overtime : remaining;

        final progress = isOvertime
        final now = DateTime.now();
        final left = session!.remaining(now);
        final progress = session.total.inSeconds == 0
            ? 1.0
            : activeSession.total.inSeconds == 0
                ? 1.0
                : 1 - remaining.inSeconds / activeSession.total.inSeconds;

        return [
          Text(
            _clock(displayedTime),
            textAlign: TextAlign.center,
            style: RestType.serif(72),
          Semantics(
            liveRegion: false,
            label: session.isPaused(now)
                ? 'Focus timer paused, ${formatDuration(minutesLeft(left))} left'
                : '${formatDuration(minutesLeft(left))} left',
            label: AppLocalizations.of(context).timeLeft(localizedDuration(AppLocalizations.of(context), left.inMinutes + (left.inSeconds % 60 > 0 ? 1 : 0))),
            child: Text(
              formatClock(left),
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
              color: isOvertime ? Colors.green : RestPalette.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isOvertime
                ? 'Your planned time is over. Your apps will stay set aside '
                    'until you end the session.'
                : 'Your apps are set aside until '
                    '${formatTime(activeSession.endsAt.toLocal())}.',
            'Your apps are set aside until '
            '${formatTime(session.endsAt(now).toLocal())}.',
            AppLocalizations.of(context).appsSetAsideUntil(formatTime(session.endsAt.toLocal())),
            textAlign: TextAlign.center,
            style: RestType.sans(16, color: RestPalette.accent),
          ),
          const SizedBox(height: 28),
          Text(
            isOvertime
                ? 'You can end your session whenever you’re ready.'
                : '“Return gently whenever your attention wanders.”',
            '“${AppLocalizations.of(context).momentFocusStep3}”',
            textAlign: TextAlign.center,
            style: RestType.serif(24).copyWith(fontStyle: FontStyle.italic),
          ),
        ];

      case _Phase.finished:
        return [
          Text(
            _endedEarly ? AppLocalizations.of(context).sessionEnded : AppLocalizations.of(context).wellDone,
            textAlign: TextAlign.center,
            style: RestType.serif(40),
          ),
          const SizedBox(height: 12),
          Text(
            _endedEarly
                ? AppLocalizations.of(context).sessionEndedEarlyBody
                : AppLocalizations.of(context).sessionCompleteBody,
            textAlign: TextAlign.center,
            style: RestType.sans(16, color: RestPalette.accent),
          ),
        ];

      case _Phase.failed:
        return [
          Text(
            _error ?? AppLocalizations.of(context).somethingWentWrong,
            textAlign: TextAlign.center,
            style: RestType.sans(16),
          ),
        ];

      case _Phase.releaseFailed:
        return [
          Text(
            AppLocalizations.of(context).appsStillSetAside,
            textAlign: TextAlign.center,
            style: RestType.serif(32),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).releaseFailedBody,
            textAlign: TextAlign.center,
            style: RestType.sans(16, color: RestPalette.accent),
          ),
        ];
    }
  }

  List<Widget> _actions() {
    switch (_phase) {
      case _Phase.running:
        final notice = _notice;
        return [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: notice == null
                ? const SizedBox.shrink()
                : Padding(
                    key: ValueKey(notice),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: RestPalette.surface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: RestPalette.border),
                        ),
                        child: Text(
                          notice,
                          textAlign: TextAlign.center,
                          style: RestType.sans(13),
                        ),
                      ),
                    ),
                  ),
          ),
          TextButton(
            onPressed: _needAnApp,
            style: TextButton.styleFrom(
              foregroundColor: RestPalette.primary,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(
              AppLocalizations.of(context).needAnApp,
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
              AppLocalizations.of(context).endEarly,
              style: RestType.sans(
                17,
                color: RestPalette.primary,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ];

      case _Phase.overtime:
        return [
          MomentPrimaryButton(
            label: 'End session',
            onPressed: () => _finish(early: false),
          ),
        ];

      case _Phase.finished:
      case _Phase.failed:
        return [
          MomentPrimaryButton(label: 'Done', onPressed: _leave),
        ];

        return [MomentPrimaryButton(label: AppLocalizations.of(context).done, onPressed: _leave)];
      case _Phase.releaseFailed:
        return [
          MomentPrimaryButton(label: AppLocalizations.of(context).tryAgain, onPressed: _retryRelease),
        ];

      case _Phase.starting:
      case _Phase.ending:
        return const [];
    }
  }
}