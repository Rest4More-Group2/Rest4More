import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'today_screen.dart';

class DailyTimerScreen extends StatefulWidget {
  const DailyTimerScreen({
    super.key,
    required this.minutes,
  }) : assert(minutes > 0);

  final int minutes;

  @override
  State<DailyTimerScreen> createState() => _DailyTimerScreenState();
}

class _DailyTimerScreenState extends State<DailyTimerScreen>
    with WidgetsBindingObserver {
  Timer? _ticker;
  DateTime? _endsAt;

  late int _secondsLeft;
  bool _running = false;
  bool _finished = false;

  int get _totalSeconds => widget.minutes * 60;

  String get _timeLabel {
    final minutes = _secondsLeft ~/ 60;
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void initState() {
    super.initState();
    _secondsLeft = _totalSeconds;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateRemaining();
    }
  }

  void _start() {
    if (_running || _finished) return;

    setState(() {
      _endsAt = DateTime.now().toUtc().add(
        Duration(seconds: _totalSeconds),
      );
      _running = true;
    });

    _ticker = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _updateRemaining(),
    );
  }

  void _updateRemaining() {
    final end = _endsAt;
    if (!mounted || !_running || end == null) return;

    final milliseconds =
        end.difference(DateTime.now().toUtc()).inMilliseconds;
    final seconds = math.max(0, (milliseconds / 1000).ceil());

    if (seconds == _secondsLeft) return;

    if (seconds == 0) {
      _ticker?.cancel();
    }

    setState(() {
      _secondsLeft = seconds;
      if (seconds == 0) {
        _running = false;
        _finished = true;
      }
    });
  }

  Future<void> _stop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: RestPalette.background,
        title: Text('Stop this moment?', style: RestType.serif(28)),
        content: Text(
          'Your daily step will stay unfinished.',
          style: RestType.sans(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Stop moment'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    _ticker?.cancel();
    setState(() {
      _endsAt = null;
      _running = false;
      _finished = false;
      _secondsLeft = _totalSeconds;
    });
  }

  void _back() {
    if (_running) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Use Stop to end this moment, or leave the app to keep it going.',
          ),
        ),
      );
      return;
    }

    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _secondsLeft / _totalSeconds;

    return PopScope(
      canPop: !_running,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: RestPalette.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _back,
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Back'),
                        style: TextButton.styleFrom(
                          foregroundColor: RestPalette.accent,
                          textStyle: RestType.sans(14),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${widget.minutes}-minute quiet moment',
                      style: RestType.serif(32),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _finished
                          ? 'A little space for yourself. Well done.'
                          : 'Take a few minutes away from your phone.',
                      textAlign: TextAlign.center,
                      style: RestType.sans(
                        15,
                        color: RestPalette.accent,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Center(
                      child: SizedBox(
                        width: 240,
                        height: 240,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 4,
                                backgroundColor: RestPalette.border,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _running
                                      ? RestPalette.primary
                                      : RestPalette.border,
                                ),
                              ),
                            ),
                            Container(
                              width: 202,
                              height: 202,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: RestPalette.surface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _timeLabel,
                                    style: RestType.serif(48),
                                  ),
                                  Text(
                                    _finished ? 'completed' : 'remaining',
                                    style: RestType.sans(
                                      12,
                                      color: RestPalette.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 56),
                    RestActionButton(
                      label: _finished
                          ? 'Finish daily step'
                          : _running
                              ? 'Stop'
                              : 'Start',
                      onPressed: () {
                        if (_finished) {
                          Navigator.pop(context, true);
                        } else if (_running) {
                          _stop();
                        } else {
                          _start();
                        }
                      },
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