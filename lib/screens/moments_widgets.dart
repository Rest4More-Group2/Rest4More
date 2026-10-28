import 'dart:math' as math;

import 'package:flutter/material.dart';

class RestMomentIcon extends StatelessWidget {
  const RestMomentIcon({
    super.key,
    required this.index,
    required this.color,
    this.size = 24,
  });
  final int index;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _MomentIconPainter(index, color)),
    ),
  );
}

class _MomentIconPainter extends CustomPainter {
  const _MomentIconPainter(this.index, this.color);
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
          canvas.drawOval(
            Rect.fromCenter(center: Offset(9.5, y), width: 5, height: 5),
            pen,
          );
          canvas.drawOval(
            Rect.fromCenter(center: Offset(14.5, y), width: 5, height: 5),
            pen,
          );
        }
        canvas.drawLine(const Offset(12, 15), const Offset(12, 21), pen);
        canvas.drawPath(
          Path()
            ..moveTo(12, 20)
            ..quadraticBezierTo(6, 21, 6, 16)
            ..quadraticBezierTo(11, 16, 12, 20)
            ..quadraticBezierTo(18, 21, 18, 16)
            ..quadraticBezierTo(13, 16, 12, 20),
          pen,
        );
        break;
      case 2:
        canvas.drawCircle(const Offset(12, 12), 9, pen);
        canvas.drawPath(
          Path()
            ..moveTo(16, 7)
            ..lineTo(14, 14)
            ..lineTo(8, 17)
            ..lineTo(10, 10)
            ..close(),
          pen,
        );
        break;
      case 3:
        canvas.drawCircle(const Offset(12, 7.5), 4, pen);
        canvas.drawPath(
          Path()
            ..moveTo(4.5, 21)
            ..cubicTo(4.5, 10, 19.5, 10, 19.5, 21),
          pen,
        );
        break;
      case 4:
        // A tag with signal arcs.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3.5, 11, 11, 9.5),
            const Radius.circular(2.5),
          ),
          pen,
        );
        for (final r in [4.0, 7.5]) {
          canvas.drawArc(
            Rect.fromCircle(center: const Offset(14.5, 9.5), radius: r),
            -math.pi / 2,
            math.pi / 2,
            false,
            pen,
          );
        }
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MomentIconPainter oldDelegate) =>
      oldDelegate.index != index || oldDelegate.color != color;
}
