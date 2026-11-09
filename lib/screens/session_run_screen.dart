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

enum _Phase {
  starting,
  running,
  overtime,
  ending,
  finished,
  failed,
  releaseFailed,
}

/// Een lopende sessie met timer (Focus of Reading). Start de blokkade, telt af
/// naar het eindtijdstip en geeft de apps weer vrij. Eerder stoppen gaat via
/// [EndEarlyScreen] en wordt als `stoppedEarly` vastgelegd.
///
/// Zolang de apps tijdelijk vrij zijn ("Need an app?") staat de timer stil en
/// ligt [UnblockedScreen] erbovenop. Daarna loopt hij verder waar hij stond en
/// schuift het einde zo lang op.
class SessionRunScreen extends ConsumerStatefulWidget {
  const SessionRunScreen({
    super.key,
    this.setup,
    this.resume,
    this.manualKind,
    this.manualMinutes,
  }) : assert(setup != null || resume != null || manualKind != null);

  /// Een nieuwe sessie starten.
  final FocusSetup? setup;

  /// Een al lopende sessie weer tonen.
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
      // Er loopt al een sessie: laat die zien in plaats van hem te vervangen.
      if (mounted) _run(e.running);
    } on SessionStartError {
      if (!mounted) return;
      _fail(AppLocalizations.of(context).sessionStartBlockFailed);
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
    _wasPaused = session.isPaused(DateTime.now());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    // Pauzes komen uit het logboek van de sessie; zo klopt de timer ook als
    // een ander scherm de apps vrijgeeft of weer dichtzet.
    _watch = _runner.watchCurrent().listen((fresh) {
      if (fresh != null && fresh.id == session.id && mounted) {
        _session = fresh;
        _tick();
      }
    }, onError: (Object _) {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
    _notificationWork = _scheduleSessionEndNotification(session);
  }

  Future<void> _scheduleSessionEndNotification(RunningSession session) async {
    // The text is chosen now, in the app's language, because the scheduler
    // fires it later without access to the UI.
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(reminderSchedulerProvider)
          .scheduleSessionEnd(
            sessionId: session.id,
            title: l10n.sessionEndNotifTitle(
              momentKindName(l10n, session.kind),
            ),
            body: l10n.sessionEndNotifBody,
            endsAt: session.endsAt(DateTime.now()),
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
      // Keep the overtime clock updating and reapply an expired app unblock.
      ref.read(unblockServiceProvider).reapplyIfExpired().ignore();
      setState(() {});
      return;
    }
    if (_phase != _Phase.running) return;
    final now = DateTime.now();
    final paused = session.isPaused(now);
    if (_wasPaused && !paused) _showResumed(session, now);
    _wasPaused = paused;
    if (session.isOver(now)) {
      // Keep the ticker running. The user ends the session manually.
      setState(() => _phase = _Phase.overtime);
    } else if (paused &&
        !_unblockOpen &&
        (ModalRoute.of(context)?.isCurrent ?? false)) {
      // Na een herstart midden in een pauze: het juiste scherm terug.
      _showUnblocked(session, session.activePause(now)!);
    } else {
      // iOS: een tijdelijk vrijgegeven blokkade weer dichtzetten als de tijd om is.
      ref.read(unblockServiceProvider).reapplyIfExpired().ignore();
      setState(() {});
    }
  }

  Future<void> _finish({required bool early}) async {
    final l10n = AppLocalizations.of(context);
    final session = _session;
    if (session == null || _phase == _Phase.ending) return;
    _ticker?.cancel();
    setState(() => _phase = _Phase.ending);
    _endedEarly = early;
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
          SnackBar(
            content: Text(
              AppLocalizations.of(context).appsStillSetAsideTryAgain,
            ),
          ),
        );
      }
    }
  }

  /// Een app tijdelijk vrijgeven, bewust en niet te makkelijk. De timer
  /// staat pas stil vanaf "Unblock", niet tijdens de pauze ervoor.
  Future<void> _needAnApp() async {
    final session = _session;
    if (session == null || _phase != _Phase.running || _unblockOpen) return;
    _unblockOpen = true;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const UnblockFlowScreen()),
    );
    await _afterUnblock(session);
  }

  Future<void> _showUnblocked(
    RunningSession session,
    SessionPause pause,
  ) async {
    _unblockOpen = true;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => UnblockedScreen(
          until: pause.until,
          granted: pause.until.difference(pause.start),
          session: session,
        ),
      ),
    );
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
    final end = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const EndEarlyScreen()),
    );
    _askingToStop = false;
    // De sessie kan intussen vanzelf afgelopen zijn.
    if (end == true && mounted && _phase == _Phase.running) {
      await _finish(early: true);
    }
  }

  void _leave() => Navigator.of(context).popUntil((route) => route.isFirst);

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final l10n = AppLocalizations.of(context);
    final title =
        session?.kind.profileName ??
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
      canPop:
          _phase == _Phase.overtime ||
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
                ? AppLocalizations.of(context).settingAppsAside
                : AppLocalizations.of(context).bringingAppsBack,
            textAlign: TextAlign.center,
            style: RestType.sans(16, color: RestPalette.accent),
          ),
        ];
      case _Phase.running:
      case _Phase.overtime:
        final isOvertime = _phase == _Phase.overtime;
        final now = DateTime.now();
        final left = session!.remaining(now);
        final over = now.difference(session.endsAt(now));
        final progress = isOvertime || session.total.inSeconds == 0
            ? 1.0
            : 1 - left.inSeconds / session.total.inSeconds;
        return [
          Semantics(
            liveRegion: false,
            label: isOvertime
                ? formatClock(over)
                : AppLocalizations.of(context).timeLeft(
                    localizedDuration(
                      AppLocalizations.of(context),
                      minutesLeft(left),
                    ),
                  ),
            child: Text(
              formatClock(isOvertime ? over : left),
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
                ? AppLocalizations.of(context).sessionOvertimeBody
                : AppLocalizations.of(context).appsSetAsideUntil(
                    formatTime(session.endsAt(now).toLocal()),
                  ),
            textAlign: TextAlign.center,
            style: RestType.sans(16, color: RestPalette.accent),
          ),
          const SizedBox(height: 28),
          Text(
            isOvertime
                ? AppLocalizations.of(context).sessionOvertimeHint
                : '“${AppLocalizations.of(context).momentFocusStep3}”',
            textAlign: TextAlign.center,
            style: RestType.serif(24).copyWith(fontStyle: FontStyle.italic),
          ),
        ];
      case _Phase.finished:
        return [
          Text(
            _endedEarly
                ? AppLocalizations.of(context).sessionEnded
                : AppLocalizations.of(context).wellDone,
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
                          horizontal: 16,
                          vertical: 12,
                        ),
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
            label: AppLocalizations.of(context).endSessionButton,
            onPressed: () => _finish(early: false),
          ),
        ];
      case _Phase.finished:
      case _Phase.failed:
        return [
          MomentPrimaryButton(
            label: AppLocalizations.of(context).done,
            onPressed: _leave,
          ),
        ];
      case _Phase.releaseFailed:
        return [
          MomentPrimaryButton(
            label: AppLocalizations.of(context).tryAgain,
            onPressed: _retryRelease,
          ),
        ];
      case _Phase.starting:
      case _Phase.ending:
        return const [];
    }
  }
}
