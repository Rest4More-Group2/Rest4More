import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/data/moments/moment_schedule.dart';
import 'package:rest4more/data/moments/session_runner.dart';
import 'package:rest4more/providers/repository_providers.dart';

import 'moments_form_widgets.dart';
import 'today_screen.dart' show RestPalette, RestType;

/// In de laatste minuut gaat het scherm over op "Almost time".
const lockingSoon = Duration(seconds: 60);

/// De apps zijn tijdelijk vrij. Telt af naar [until]; de timer van de sessie
/// staat intussen stil. "Block apps again" of het einde van de tijd zet de
/// apps weer dicht en gaat terug naar de sessie, waar de timer verder loopt.
///
/// Terug (Android) en terugvegen (iOS) doen hier niets: zo gaan de apps nooit
/// stil weer dicht, en staat de sessie nooit stil zonder dit scherm.
class UnblockedScreen extends ConsumerStatefulWidget {
  const UnblockedScreen({
    super.key,
    required this.until,
    required this.granted,
    this.appName,
    this.session,
    this.now,
  });

  /// Tot wanneer de apps vrij zijn.
  final DateTime until;

  /// Hoe lang de vrijgave in totaal duurt, voor de balk.
  final Duration granted;

  /// De vrijgegeven app (Android), of null voor alle apps.
  final String? appName;

  /// De gepauzeerde sessie, als er een loopt.
  final RunningSession? session;
  final DateTime Function()? now;

  @override
  ConsumerState<UnblockedScreen> createState() => _UnblockedScreenState();
}

class _UnblockedScreenState extends ConsumerState<UnblockedScreen>
    with WidgetsBindingObserver {
  Timer? _ticker;
  bool _relocking = false;
  bool _announcedSoon = false;
  String? _error;

  DateTime get _now => (widget.now ?? DateTime.now)();

  Duration get _left {
    final left = widget.until.difference(_now);
    return left.isNegative ? Duration.zero : left;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    // Al voorbij (bijvoorbeeld na een herstart): meteen weer dicht.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // De tijd kan om zijn gegaan terwijl de app op de achtergrond stond.
    if (state == AppLifecycleState.resumed) _tick();
  }

  void _tick() {
    if (!mounted || _relocking) return;
    final left = _left;
    if (left == Duration.zero) {
      _relock(auto: true);
      return;
    }
    if (left <= lockingSoon && !_announcedSoon) {
      _announcedSoon = true;
      SemanticsService.sendAnnouncement(
        View.of(context),
        'Almost time. Apps lock in under a minute.',
        TextDirection.ltr,
      );
    }
    setState(() {});
  }

  /// Zet de apps weer dicht en laat de timer van de sessie verder lopen.
  /// Vanzelf ([auto]) gaat dat altijd door: op het toestel is de vrijgave dan
  /// ook al voorbij.
  Future<void> _relock({required bool auto}) async {
    if (_relocking) return;
    _ticker?.cancel();
    setState(() {
      _relocking = true;
      _error = null;
    });
    try {
      await ref.read(unblockServiceProvider).revoke();
    } on Object {
      if (!auto) {
        if (mounted) {
          setState(() {
            _relocking = false;
            _error =
                'We could not block your apps right now. '
                'Please try again.';
          });
          _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
        }
        return;
      }
    }
    final session = widget.session;
    if (session != null) {
      // Het logboek. Mislukt dat, dan loopt de timer toch weer verder zodra
      // de vrijgegeven tijd om is.
      try {
        await ref.read(sessionRunnerProvider).resumeAfterUnblock(session.id);
      } on Object {
        // Alleen het logboek.
      }
    }
    if (!auto) HapticFeedback.mediumImpact();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final left = _left;
    final soon = left <= lockingSoon;
    final granted = widget.granted.inMilliseconds;
    final progress = granted == 0 ? 0.0 : left.inMilliseconds / granted;
    final name = widget.appName;
    final session = widget.session;

    return PopScope(
      canPop: false,
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
                      child: _StatusChip(
                        label: soon ? 'LOCKING SOON' : 'APPS AVAILABLE',
                        dot: soon ? RestPalette.accent : RestPalette.gold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      header: true,
                      child: Text(
                        soon ? 'Almost time' : 'Apps unlocked',
                        style: RestType.serif(44),
                      ),
                    ),
                    const Spacer(),
                    Semantics(
                      label: soon
                          ? 'Apps lock in under a minute'
                          : 'Apps lock again in '
                                '${formatDuration(minutesLeft(left))}',
                      child: ExcludeSemantics(
                        child: Text(
                          formatClock(left),
                          textAlign: TextAlign.center,
                          style: RestType.serif(72).copyWith(
                            color: soon ? RestPalette.accent : RestPalette.ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: RestPalette.surface,
                        color: RestPalette.gold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      soon
                          ? 'Apps lock in under a minute.'
                          : name == null
                          ? 'Your apps lock again at '
                                '${formatTime(widget.until.toLocal())}.'
                          : '$name locks again at '
                                '${formatTime(widget.until.toLocal())}.',
                      textAlign: TextAlign.center,
                      style: RestType.sans(16, color: RestPalette.accent),
                    ),
                    const Spacer(),
                    if (session != null) ...[
                      _PausedCard(session: session, now: _now),
                      const SizedBox(height: 16),
                    ],
                    if (_error != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: RestType.sans(14, color: RestPalette.accent),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    MomentPrimaryButton(
                      label: _relocking ? 'Blocking…' : 'Block apps again',
                      onPressed: _relocking ? null : () => _relock(auto: false),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      session != null
                          ? 'Blocks your apps now and resumes your focus timer.'
                          : 'Blocks your apps now.',
                      textAlign: TextAlign.center,
                      style: RestType.sans(13, color: RestPalette.accent),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Het label bovenaan: een gekleurde stip en een korte toestand.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.dot});

  final String label;
  final Color dot;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: label.toLowerCase(),
    child: ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: ShapeDecoration(
          color: RestPalette.surface.withValues(alpha: 0.5),
          shape: const StadiumBorder(
            side: BorderSide(color: RestPalette.border),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: RestType.sans(
                12,
                color: RestPalette.primary,
                weight: FontWeight.w600,
              ).copyWith(letterSpacing: 0.8),
            ),
          ],
        ),
      ),
    ),
  );
}

/// De stilstaande timer van de sessie. Verandert alleen als die timer dat
/// doet, en dat doet hij tijdens de pauze niet.
class _PausedCard extends StatelessWidget {
  const _PausedCard({required this.session, required this.now});

  final RunningSession session;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final left = session.remaining(now);
    final name = session.kind.profileName;
    return Semantics(
      container: true,
      label:
          'Focus timer paused. $name, '
          '${formatDuration(minutesLeft(left))} remaining',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: RestPalette.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: RestPalette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: RestPalette.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pause,
                  size: 18,
                  color: RestPalette.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Focus timer paused',
                      style: RestType.sans(15, weight: FontWeight.w600),
                    ),
                    Text(
                      '$name · ${formatClock(left)} remaining',
                      style: RestType.sans(13, color: RestPalette.accent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
