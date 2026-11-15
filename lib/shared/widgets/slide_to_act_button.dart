import 'package:flutter/material.dart';

class SlideToActButton extends StatefulWidget {
  final String text;
  final Future<bool> Function()? onSlideComplete;
  final bool isLoading;
  final bool isCompleted;
  final String? completedText;
  final Color trackColor;
  final Color thumbColor;
  final Color textColor;
  final double height;

  const SlideToActButton({
    super.key,
    required this.text,
    this.onSlideComplete,
    this.isLoading = false,
    this.isCompleted = false,
    this.completedText,
    this.trackColor = const Color(0xFFF1F5F9),
    this.thumbColor = const Color(0xFF0F172A),
    this.textColor = const Color(0xFF1E293B),
    this.height = 52.0,
  });

  @override
  State<SlideToActButton> createState() => _SlideToActButtonState();
}

class _SlideToActButtonState extends State<SlideToActButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isActionInProgress = false;
  late AnimationController _resetController;
  late Animation<double> _resetAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _resetController.addListener(() {
      setState(() {
        _dragPosition = _resetAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _resetPosition(double from) {
    _resetAnimation = Tween<double>(begin: from, end: 0.0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    );
    _resetController.forward(from: 0.0);
  }

  Future<void> _handleComplete(double maxDrag) async {
    setState(() {
      _dragPosition = maxDrag;
      _isActionInProgress = true;
    });

    if (widget.onSlideComplete != null) {
      final success = await widget.onSlideComplete!();
      if (!mounted) return;
      if (!success) {
        // Reset back if failed
        setState(() {
          _isActionInProgress = false;
        });
        _resetPosition(maxDrag);
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isActionInProgress = false;
        _dragPosition = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = widget.isLoading || _isActionInProgress;

    if (widget.isCompleted) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(widget.height / 2),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF059669),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                widget.completedText ?? 'Completed',
                style: const TextStyle(
                  color: Color(0xFF059669),
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final thumbSize = widget.height - 8.0;
        final maxDrag = totalWidth - thumbSize - 8.0;

        final double currentDrag = isBusy
            ? maxDrag
            : _dragPosition.clamp(0.0, maxDrag);
        final double progress = maxDrag > 0
            ? (currentDrag / maxDrag).clamp(0.0, 1.0)
            : 0.0;
        final double textOpacity = (1.0 - progress * 1.5).clamp(0.0, 1.0);

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.trackColor,
            borderRadius: BorderRadius.circular(widget.height / 2),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // 1. Text Label in center
              Positioned.fill(
                child: Center(
                  child: Opacity(
                    opacity: textOpacity,
                    child: Padding(
                      padding: EdgeInsets.only(left: thumbSize + 6, right: 14),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: widget.textColor,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Sliding Thumb Knob
              Positioned(
                left: 4.0 + currentDrag,
                child: GestureDetector(
                  onHorizontalDragUpdate: isBusy
                      ? null
                      : (details) {
                          setState(() {
                            _dragPosition = (_dragPosition + details.delta.dx)
                                .clamp(0.0, maxDrag);
                          });
                        },
                  onHorizontalDragEnd: isBusy
                      ? null
                      : (details) {
                          if (_dragPosition >= maxDrag * 0.70) {
                            _handleComplete(maxDrag);
                          } else {
                            _resetPosition(_dragPosition);
                          }
                        },
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: widget.thumbColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.2,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 19,
                                  color: Colors.white,
                                ),
                                Transform.translate(
                                  offset: const Offset(-9.0, 0),
                                  child: const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 19,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
