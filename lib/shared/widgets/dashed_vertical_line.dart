import 'package:flutter/material.dart';

/// A reusable vertically dashed line that aligns perfectly on the center
/// axis of an icon of width [iconWidth].
class DashedVerticalLine extends StatelessWidget {
  final double iconWidth;
  final double height;
  final Color color;
  final double dashHeight;
  final double dashGap;
  final double strokeWidth;

  const DashedVerticalLine({
    super.key,
    this.iconWidth = 14.0,
    this.height = 14.0,
    this.color = const Color(0xFFCBD5E1),
    this.dashHeight = 2.8,
    this.dashGap = 2.5,
    this.strokeWidth = 1.4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: iconWidth,
      height: height,
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size(strokeWidth, height),
        painter: _DashedLinePainter(
          color: color,
          dashHeight: dashHeight,
          dashGap: dashGap,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashHeight;
  final double dashGap;
  final double strokeWidth;

  _DashedLinePainter({
    required this.color,
    required this.dashHeight,
    required this.dashGap,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double y = 0;
    while (y < size.height) {
      final nextY = (y + dashHeight).clamp(0.0, size.height);
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, nextY),
        paint,
      );
      y += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dashHeight != dashHeight ||
      oldDelegate.dashGap != dashGap ||
      oldDelegate.strokeWidth != strokeWidth;
}
