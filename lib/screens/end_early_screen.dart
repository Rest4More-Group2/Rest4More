import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'package:rest4more/l10n/app_localizations.dart';

import 'moments_form_widgets.dart';
import 'today_screen.dart' show RestPalette, RestType;

/// Eerder stoppen met een sessie, met hetzelfde "adem even" als het tijdelijk
/// vrijgeven van een app: eerst een korte pauze, pas daarna kun je kiezen.
///
/// Geeft `true` terug als de gebruiker de sessie wil beëindigen. "Keep going",
/// het kruisje en terug (Android-knop of iOS-veeg) geven geen `true`. De
/// sessie zelf loopt hier gewoon door; dit scherm raakt de timer en de
/// blokkade niet aan.
class EndEarlyScreen extends StatefulWidget {
  const EndEarlyScreen({super.key, this.wait = waitDuration, this.now});

  static const waitDuration = Duration(seconds: 5);

  /// Hoe lang de knoppen dicht blijven.
  final Duration wait;

  /// Alleen tests passen de klok aan.
  final DateTime Function()? now;

  @override
  State<EndEarlyScreen> createState() => _EndEarlyScreenState();
}

class _EndEarlyScreenState extends State<EndEarlyScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // De balk loopt op de animatie, maar het beginmoment telt: een ticker staat
  // stil zolang de app op de achtergrond is, dus bij terugkomen halen we in.
  late final DateTime _startedAt;
  late final AnimationController _wait = AnimationController(
    vsync: this,
    duration: widget.wait,
  )..addStatusListener(_onStatus);
  bool _unlocked = false;

  DateTime get _now => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startedAt = _now;
    _wait.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wait.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _catchUp();
  }

  void _catchUp() {
    if (_unlocked) return;
    final total = widget.wait.inMicroseconds;
    final passed = _now.difference(_startedAt).inMicroseconds;
    final fraction = total == 0 ? 1.0 : (passed / total).clamp(0.0, 1.0);
    if (fraction <= _wait.value) return;
    _wait.value = fraction;
    if (fraction < 1) _wait.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    HapticFeedback.lightImpact();
    setState(() => _unlocked = true);
    SemanticsService.sendAnnouncement(
      View.of(context),
      AppLocalizations.of(context).endEarlyChooseNow,
      TextDirection.ltr,
    );
  }

  int get _secondsLeft =>
      ((1 - _wait.value) * widget.wait.inMilliseconds / 1000).ceil();

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
                MomentCloseButton(
                  tooltip: AppLocalizations.of(context).endEarlyCloseTooltip,
                ),
                const Spacer(),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _unlocked
                        ? AppLocalizations.of(context).endEarlyReadyTitle
                        : AppLocalizations.of(context).takeMomentBreathe,
                    textAlign: TextAlign.center,
                    style: RestType.serif(40),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _unlocked
                      ? AppLocalizations.of(context).endEarlyReadyBody
                      : AppLocalizations.of(context).endEarlyWaitBody,
                  textAlign: TextAlign.center,
                  style: RestType.sans(16, color: RestPalette.accent),
                ),
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _wait,
                  builder: (context, _) => _countdown(),
                ),
                const Spacer(),
                _KeepGoingButton(
                  onPressed: _unlocked
                      ? () => Navigator.pop(context, false)
                      : null,
                ),
                const SizedBox(height: 12),
                _EndSessionButton(
                  onPressed: _unlocked
                      ? () => Navigator.pop(context, true)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  _unlocked
                      ? AppLocalizations.of(context).endEarlyLogged
                      : AppLocalizations.of(context)
                            .endEarlyUnlockAfter(widget.wait.inSeconds),
                  textAlign: TextAlign.center,
                  style: RestType.sans(14, color: RestPalette.accent),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _countdown() {
    final l10n = AppLocalizations.of(context);
    final left = _secondsLeft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(child: BreatheBar(value: _wait.value)),
        const SizedBox(height: 20),
        // Telt per seconde af; een schermlezer leest elke verandering voor.
        Semantics(
          liveRegion: true,
          label: _unlocked
              ? l10n.endEarlyChooseNow
              : l10n.endEarlyChooseIn(left),
          excludeSemantics: true,
          child: Text(
            _unlocked
                ? l10n.endEarlyChooseNow
                : l10n.endEarlyChooseInShort(left),
            textAlign: TextAlign.center,
            style: RestType.sans(14, color: RestPalette.accent),
          ),
        ),
      ],
    );
  }
}

class _KeepGoingButton extends StatelessWidget {
  const _KeepGoingButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: RestPalette.primary,
      foregroundColor: RestPalette.background,
      disabledBackgroundColor: RestPalette.primary.withValues(alpha: 0.45),
      disabledForegroundColor: RestPalette.background,
      elevation: 0,
      shape: const StadiumBorder(),
      minimumSize: const Size(double.infinity, 58),
    ),
    child: Text(
      AppLocalizations.of(context).keepGoing,
      style: RestType.sans(
        17,
        color: RestPalette.background,
        weight: FontWeight.w600,
      ),
    ),
  );
}

/// Zelfde vorm als "End early" op het sessiescherm.
class _EndSessionButton extends StatelessWidget {
  const _EndSessionButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = onPressed == null
        ? RestPalette.primary.withValues(alpha: 0.45)
        : RestPalette.primary;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: RestPalette.primary,
        side: const BorderSide(color: RestPalette.border),
        shape: const StadiumBorder(),
        minimumSize: const Size(double.infinity, 58),
      ),
      child: Text(
        AppLocalizations.of(context).endSessionButton,
        style: RestType.sans(17, color: color, weight: FontWeight.w600),
      ),
    );
  }
}
