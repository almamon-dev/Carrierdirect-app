import 'dart:math' as math;

import 'package:flutter/material.dart';

class WaveProcessingIndicator extends StatefulWidget {
  final Color color;
  final int barCount;
  final double maxHeight;
  final double minHeight;
  final double barWidth;
  final double barSpacing;

  const WaveProcessingIndicator({
    super.key,
    this.color = Colors.white,
    this.barCount = 4,
    this.maxHeight = 16.0,
    this.minHeight = 5.0,
    this.barWidth = 3.2,
    this.barSpacing = 3.0,
  });

  @override
  State<WaveProcessingIndicator> createState() =>
      _WaveProcessingIndicatorState();
}

class _WaveProcessingIndicatorState extends State<WaveProcessingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(widget.barCount, (index) {
            // Sine wave phase offset for each bar
            final offset = (index * 0.7);
            final progress = (_controller.value * 2 * math.pi) - offset;
            final normalized = (math.sin(progress) + 1.0) / 2.0; // 0.0 to 1.0
            final barHeight =
                widget.minHeight +
                (widget.maxHeight - widget.minHeight) * normalized;

            return Container(
              width: widget.barWidth,
              height: barHeight,
              margin: EdgeInsets.symmetric(horizontal: widget.barSpacing / 2),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(widget.barWidth),
              ),
            );
          }),
        );
      },
    );
  }
}
