import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'make_it_smaller_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({
    super.key,
    this.day = 4,
    this.totalDays = 14,
    this.minutes = 20,
    this.smallerMinutes = 5,
    this.greeting = 'Good morning',
    this.invitation = 'Make a little room for rest',
    this.description =
        'Today’s step is based on your goal and the routine you chose.',
    this.explanation =
        'A quiet moment gives you space to put your phone aside and settle '
        'into your chosen routine. Start with a duration that feels achievable.',
    this.onStartStep,
    this.onMakeSmaller,
    this.onWhyStep,
  }) : assert(day >= 1 && day <= totalDays),
       assert(
         minutes > 0 &&
             smallerMinutes > 0 &&
             smallerMinutes <= minutes,
       );

  final int day;
  final int totalDays;
  final int minutes;
  final int smallerMinutes;

  final String greeting;
  final String invitation;
  final String description;
  final String explanation;

  /// Connect this to the actual moment/timer flow.
  final ValueChanged<int>? onStartStep;

  final ValueChanged<int>? onMakeSmaller;

  final VoidCallback? onWhyStep;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late int _minutes;

  @override
  void initState() {
    super.initState();
    _minutes = widget.minutes;
  }

  @override
  void didUpdateWidget(covariant TodayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.minutes != widget.minutes ||
        oldWidget.day != widget.day) {
      _minutes = widget.minutes;
    }
  }

  Future<void> _makeSmaller() async {
    final selectedMinutes = await Navigator.push<int>(
      context,
      MaterialPageRoute<int>(
        builder: (context) => MakeItSmallerScreen(
          originalMinutes: widget.minutes,
          smallerMinutes: widget.smallerMinutes,
        ),
      ),
    );

    if (!mounted || selectedMinutes == null) return;

    setState(() {
      _minutes = selectedMinutes;
    });

    if (selectedMinutes == widget.smallerMinutes &&
        selectedMinutes < widget.minutes) {
      widget.onMakeSmaller?.call(selectedMinutes);
      _startStep();
    }
  }

  void _startStep() {
    if (widget.onStartStep != null) {
      widget.onStartStep!(_minutes);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Connect onStartStep to your rest session screen.',
        ),
      ),
    );
  }

  void _showWhy() {
    if (widget.onWhyStep != null) {
      widget.onWhyStep!();
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: RestPalette.background,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Why this step?',
                style: RestType.serif(30),
              ),
              const SizedBox(height: 16),
              Text(
                widget.explanation,
                style: RestType.sans(16),
              ),
              const SizedBox(height: 24),
              RestActionButton(
                label: 'Got it',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: RestPalette.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: RestPalette.background,

        // Bottom navigation is NOT handled here anymore.
        // The AppShell owns the navigation between:
        // Today, Moments, Progress and Profile.

        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(
                constraints.maxWidth,
                520.0,
              );

              final scale =
                  (width / 390).clamp(0.85, 1.34).toDouble();

              return SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: width,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        24 * scale,
                        32 * scale,
                        24 * scale,
                        40 * scale,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'DAY ${widget.day} OF ${widget.totalDays}',
                            style: RestType.sans(
                              11 * scale,
                              color: RestPalette.accent,
                              weight: FontWeight.w600,
                            ),
                          ),

                          SizedBox(height: 8 * scale),

                          Text(
                            widget.greeting,
                            style: RestType.serif(
                              40 * scale,
                            ),
                          ),

                          SizedBox(height: 26 * scale),

                          InvitationCard(
                            title: widget.invitation,
                            description: widget.description,
                            scale: scale,
                          ),

                          SizedBox(height: 46 * scale),

                          QuietMomentCard(
                            minutes: _minutes,
                            scale: scale,
                          ),

                          SizedBox(height: 48 * scale),

                          RestActionButton(
                            label: 'Start today’s step',
                            onPressed: _startStep,
                            scale: scale,
                          ),

                          SizedBox(height: 22 * scale),

                          RestActionButton(
                            label: 'Make it smaller',
                            onPressed: _makeSmaller,
                            outlined: true,
                            scale: scale,
                          ),

                          SizedBox(height: 34 * scale),

                          Center(
                            child: TextButton(
                              onPressed: _showWhy,
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    RestPalette.accent,
                                minimumSize:
                                    const Size(48, 48),
                                textStyle: RestType.sans(
                                  16 * scale,
                                ),
                              ),
                              child: const Text(
                                'Why this step?',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// COLORS
// -----------------------------------------------------------------------------

class RestPalette {
  static const background = Color(0xFFFAF8F5);
  static const surface = Color(0xFFECE7DB);
  static const ink = Color(0xFF554237);
  static const primary = Color(0xFF7D573D);
  static const accent = Color(0xFFAA7657);
  static const border = Color(0xFFE5DCCD);
  static const badge = Color(0xFFF1E0BD);
}

// -----------------------------------------------------------------------------
// TYPOGRAPHY
// -----------------------------------------------------------------------------

class RestType {
  static TextStyle serif(double size) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: RestPalette.ink,
        height: 1.12,
      );

  static TextStyle sans(
    double size, {
    Color color = RestPalette.ink,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.45,
      );
}

// -----------------------------------------------------------------------------
// INVITATION CARD
// -----------------------------------------------------------------------------

class InvitationCard extends StatelessWidget {
  const InvitationCard({
    super.key,
    required this.title,
    required this.description,
    this.scale = 1,
  });

  final String title;
  final String description;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20 * scale),
      decoration: BoxDecoration(
        color: RestPalette.surface,
        borderRadius: BorderRadius.circular(
          18 * scale,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 10 * scale,
              vertical: 4 * scale,
            ),
            decoration: const BoxDecoration(
              color: RestPalette.badge,
              borderRadius: BorderRadius.all(
                Radius.circular(100),
              ),
            ),
            child: Text(
              'TODAY’S INVITATION',
              style: RestType.sans(
                10.5 * scale,
                color: RestPalette.primary,
                weight: FontWeight.w600,
              ),
            ),
          ),

          SizedBox(height: 14 * scale),

          Text(
            title,
            style: RestType.serif(
              27 * scale,
            ),
          ),

          SizedBox(height: 14 * scale),

          Text(
            description,
            style: RestType.sans(
              14 * scale,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// QUIET MOMENT CARD
// -----------------------------------------------------------------------------

class QuietMomentCard extends StatelessWidget {
  const QuietMomentCard({
    super.key,
    required this.minutes,
    this.scale = 1,
  });

  final int minutes;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: 66 * scale,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 20 * scale,
        vertical: 20 * scale,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: RestPalette.border,
        ),
        borderRadius: BorderRadius.circular(
          18 * scale,
        ),
      ),
      child: Text(
        '$minutes minute quiet moment',
        style: RestType.serif(
          22 * scale,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ACTION BUTTON
// -----------------------------------------------------------------------------

class RestActionButton extends StatelessWidget {
  const RestActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.scale = 1,
  });

  final String label;
  final VoidCallback onPressed;
  final bool outlined;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(
          double.infinity,
          52 * scale,
        ),
      ),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: 20 * scale,
          vertical: 13 * scale,
        ),
      ),
      textStyle: WidgetStatePropertyAll(
        RestType.sans(
          16 * scale,
          weight: FontWeight.w600,
        ),
      ),
      foregroundColor: WidgetStatePropertyAll(
        outlined
            ? RestPalette.primary
            : RestPalette.background,
      ),
      backgroundColor: WidgetStatePropertyAll(
        outlined
            ? Colors.transparent
            : RestPalette.primary,
      ),
      shape: const WidgetStatePropertyAll(
        StadiumBorder(),
      ),
      side: WidgetStatePropertyAll(
        outlined
            ? const BorderSide(
                color: RestPalette.primary,
              )
            : BorderSide.none,
      ),
      elevation:
          const WidgetStatePropertyAll(0),
    );

    return outlined
        ? OutlinedButton(
            onPressed: onPressed,
            style: style,
            child: Text(label),
          )
        : FilledButton(
            onPressed: onPressed,
            style: style,
            child: Text(label),
          );
  }
}