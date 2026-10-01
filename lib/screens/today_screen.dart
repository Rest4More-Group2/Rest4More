import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Add google_fonts with: flutter pub add google_fonts
/// This screen can be pushed from your existing app; it creates no nested app.
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
    this.onDestinationSelected,
  }) : assert(day >= 1 && day <= totalDays),
       assert(minutes > 0 && smallerMinutes > 0 && smallerMinutes <= minutes);

  final int day;
  final int totalDays;
  final int minutes;
  final int smallerMinutes;
  final String greeting;
  final String invitation;
  final String description;
  final String explanation;

  /// Connect this to your actual moment/timer flow. The argument is the
  /// current duration, including any change made with "Make it smaller".
  final ValueChanged<int>? onStartStep;
  final ValueChanged<int>? onMakeSmaller;
  final VoidCallback? onWhyStep;

  /// 0 = Today, 1 = Moments, 2 = Progress, 3 = Profile.
  /// The parent app owns destination changes and their screens.
  final ValueChanged<int>? onDestinationSelected;

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
    if (oldWidget.minutes != widget.minutes || oldWidget.day != widget.day) {
      _minutes = widget.minutes;
    }
  }

  void _makeSmaller() {
    setState(() => _minutes = widget.smallerMinutes);
    widget.onMakeSmaller?.call(_minutes);
  }

  void _startStep() {
    if (widget.onStartStep != null) {
      widget.onStartStep!(_minutes);
      return;
    }
    // Preview feedback only: a real rest session is not started here.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connect onStartStep to your rest session screen.'),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Why this step?', style: RestType.serif(30)),
              const SizedBox(height: 16),
              Text(widget.explanation, style: RestType.sans(16)),
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
        bottomNavigationBar: RestBottomNavigation(
          onSelected: (index) {
            if (widget.onDestinationSelected != null) {
              widget.onDestinationSelected!(index);
            } else if (index != 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Connect onDestinationSelected to your tabs.'),
                ),
              );
            }
          },
        ),
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Reference proportions, with a capped width for larger devices.
              final width = math.min(constraints.maxWidth, 520.0);
              final scale = (width / 390).clamp(0.85, 1.34).toDouble();
              return SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: width,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        24 * scale, 32 * scale, 24 * scale, 40 * scale,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          Text(widget.greeting, style: RestType.serif(40 * scale)),
                          SizedBox(height: 26 * scale),
                          InvitationCard(
                            title: widget.invitation,
                            description: widget.description,
                            scale: scale,
                          ),
                          SizedBox(height: 46 * scale),
                          QuietMomentCard(minutes: _minutes, scale: scale),
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
                                foregroundColor: RestPalette.accent,
                                minimumSize: const Size(48, 48),
                                textStyle: RestType.sans(16 * scale),
                              ),
                              child: const Text('Why this step?'),
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

class RestPalette {
  static const background = Color(0xFFFAF8F5);
  static const surface = Color(0xFFECE7DB);
  static const ink = Color(0xFF554237);
  static const primary = Color(0xFF7D573D);
  static const accent = Color(0xFFAA7657);
  static const border = Color(0xFFE5DCCD);
  static const badge = Color(0xFFF1E0BD);
}

/// Font families inferred from the screenshot, not extracted from Figma.
class RestType {
  static TextStyle serif(double size) => GoogleFonts.cormorantGaramond(
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: RestPalette.ink,
    height: 1.12,
  );

  static TextStyle sans(
    double size, {
    Color color = RestPalette.ink,
    FontWeight weight = FontWeight.w400,
  }) => GoogleFonts.manrope(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.45,
  );
}

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
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(20 * scale),
    decoration: BoxDecoration(
      color: RestPalette.surface,
      borderRadius: BorderRadius.circular(18 * scale),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 4 * scale),
          decoration: const BoxDecoration(
            color: RestPalette.badge,
            borderRadius: BorderRadius.all(Radius.circular(100)),
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
        Text(title, style: RestType.serif(27 * scale)),
        SizedBox(height: 14 * scale),
        Text(description, style: RestType.sans(14 * scale)),
      ],
    ),
  );
}

class QuietMomentCard extends StatelessWidget {
  const QuietMomentCard({super.key, required this.minutes, this.scale = 1});
  final int minutes;
  final double scale;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(minHeight: 66 * scale),
    padding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 20 * scale),
    decoration: BoxDecoration(
      border: Border.all(color: RestPalette.border),
      borderRadius: BorderRadius.circular(18 * scale),
    ),
    child: Text('$minutes minute quiet moment', style: RestType.serif(22 * scale)),
  );
}

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
      minimumSize: WidgetStatePropertyAll(Size(double.infinity, 52 * scale)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 13 * scale),
      ),
      textStyle: WidgetStatePropertyAll(
        RestType.sans(16 * scale, weight: FontWeight.w600),
      ),
      foregroundColor: WidgetStatePropertyAll(
        outlined ? RestPalette.primary : RestPalette.background,
      ),
      backgroundColor: WidgetStatePropertyAll(
        outlined ? Colors.transparent : RestPalette.primary,
      ),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      side: WidgetStatePropertyAll(
        outlined ? const BorderSide(color: RestPalette.primary) : BorderSide.none,
      ),
      elevation: const WidgetStatePropertyAll(0),
    );
    return outlined
        ? OutlinedButton(onPressed: onPressed, style: style, child: Text(label))
        : FilledButton(onPressed: onPressed, style: style, child: Text(label));
  }
}

class RestBottomNavigation extends StatelessWidget {
  const RestBottomNavigation({super.key, required this.onSelected});
  final ValueChanged<int> onSelected;
  static const _labels = ['Today', 'Moments', 'Progress', 'Profile'];

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: RestPalette.surface,
      border: Border(top: BorderSide(color: RestPalette.border)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
        child: Row(
          children: List.generate(4, (index) {
            final color = index == 0 ? RestPalette.primary : RestPalette.accent;
            return Expanded(
              child: Semantics(
                selected: index == 0,
                child: TextButton(
                  onPressed: () => onSelected(index),
                  style: TextButton.styleFrom(
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExcludeSemantics(
                        child: SizedBox.square(
                          dimension: 24,
                          child: CustomPaint(painter: _RestIconPainter(index, color)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(_labels[index], style: RestType.sans(11, color: color)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    ),
  );
}

/// Original vector drawings approximating the four outline icons in the design.
class _RestIconPainter extends CustomPainter {
  const _RestIconPainter(this.index, this.color);
  final int index;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (index) {
      case 0:
        canvas.drawCircle(const Offset(12, 12), 3.6, pen);
        for (var i = 0; i < 8; i++) {
          final angle = i * math.pi / 4;
          canvas.drawLine(
            Offset(12 + 7.3 * math.cos(angle), 12 + 7.3 * math.sin(angle)),
            Offset(12 + 9.6 * math.cos(angle), 12 + 9.6 * math.sin(angle)),
            pen,
          );
        }
        break;
      case 1:
        for (final y in [5.0, 9.0, 13.0]) {
          canvas.drawOval(Rect.fromCenter(center: Offset(9.5, y), width: 5, height: 5), pen);
          canvas.drawOval(Rect.fromCenter(center: Offset(14.5, y), width: 5, height: 5), pen);
        }
        canvas.drawLine(const Offset(12, 15), const Offset(12, 21), pen);
        canvas.drawPath(
          Path()..moveTo(12, 20)..quadraticBezierTo(6, 21, 6, 16)
            ..quadraticBezierTo(11, 16, 12, 20)
            ..quadraticBezierTo(18, 21, 18, 16)
            ..quadraticBezierTo(13, 16, 12, 20),
          pen,
        );
        break;
      case 2:
        canvas.drawCircle(const Offset(12, 12), 9, pen);
        canvas.drawPath(
          Path()..moveTo(16, 7)..lineTo(14, 14)..lineTo(8, 17)
            ..lineTo(10, 10)..close(),
          pen,
        );
        break;
      case 3:
        canvas.drawCircle(const Offset(12, 7.5), 4, pen);
        canvas.drawPath(
          Path()..moveTo(4.5, 21)..cubicTo(4.5, 10, 19.5, 10, 19.5, 21),
          pen,
        );
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RestIconPainter oldDelegate) =>
      oldDelegate.index != index || oldDelegate.color != color;
}
