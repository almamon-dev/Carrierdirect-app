import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';

enum ToastType { success, error, info, warning }

class AppToast {
  static OverlayEntry? _currentEntry;

  /// Display a smooth, top-floating notification toast banner
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    ToastType type = ToastType.success,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.of(context);

    Color accentColor;
    IconData defaultIcon;

    switch (type) {
      case ToastType.success:
        accentColor = const Color(0xFF10B981); // Emerald
        defaultIcon = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        accentColor = const Color(0xFFEF4444); // Crimson
        defaultIcon = Icons.error_rounded;
        break;
      case ToastType.warning:
        accentColor = const Color(0xFFF59E0B); // Amber
        defaultIcon = Icons.warning_rounded;
        break;
      case ToastType.info:
        accentColor = AppColors.primary; // CarrierDirect Orange
        defaultIcon = Icons.info_rounded;
        break;
    }

    final displayIcon = icon ?? defaultIcon;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _TopToastWidget(
        title: title,
        message: message,
        accentColor: accentColor,
        icon: displayIcon,
        duration: duration,
        onDismiss: () {
          if (_currentEntry == entry) {
            _currentEntry?.remove();
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void success(
    BuildContext context,
    String message, {
    String? title,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    show(context, message: message, title: title, type: ToastType.success, icon: icon, duration: duration);
  }

  static void error(
    BuildContext context,
    String message, {
    String? title,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    show(context, message: message, title: title, type: ToastType.error, icon: icon, duration: duration);
  }

  static void info(
    BuildContext context,
    String message, {
    String? title,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    show(context, message: message, title: title, type: ToastType.info, icon: icon, duration: duration);
  }

  static void warning(
    BuildContext context,
    String message, {
    String? title,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    show(context, message: message, title: title, type: ToastType.warning, icon: icon, duration: duration);
  }
}

class _TopToastWidget extends StatefulWidget {
  final String? title;
  final String message;
  final Color accentColor;
  final IconData icon;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopToastWidget({
    this.title,
    required this.message,
    required this.accentColor,
    required this.icon,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    if (mounted) {
      await _controller.reverse();
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 10,
      left: 14,
      right: 14,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: _dismiss,
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                  _dismiss();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F172A), // Dark Luxury Slate
                      Color(0xFF1E293B),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: widget.accentColor.withValues(alpha: 0.45),
                    width: 1.1,
                  ),
                  boxShadow: [
                    const BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Stack(
                    children: [
                      // Accent Left Border Strip
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        width: 3.5,
                        child: Container(color: widget.accentColor),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        child: Row(
                          crossAxisAlignment: widget.title != null
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.center,
                          children: [
                            const SizedBox(width: 4),
                            // Luminous Icon Container
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: widget.accentColor.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(6.0),
                                border: Border.all(
                                  color: widget.accentColor.withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  widget.icon,
                                  color: widget.accentColor,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Text Section
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.title != null) ...[
                                    Text(
                                      widget.title!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.message,
                                      style: const TextStyle(
                                        color: Color(0xFFCBD5E1),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        height: 1.3,
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      widget.message,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Dismiss icon
                            GestureDetector(
                              onTap: _dismiss,
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
