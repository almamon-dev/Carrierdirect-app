import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';

enum ToastType { success, error, info, warning }

class AppToast {
  static OverlayEntry? _currentEntry;

  /// Dismiss any currently visible toast immediately
  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }

  /// Display a smooth, top-floating notification toast banner
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    ToastType type = ToastType.success,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2200),
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay =
        Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.of(context);

    Color accentColor;
    Color softBgColor;
    IconData defaultIcon;

    switch (type) {
      case ToastType.success:
        accentColor = const Color(0xFF10B981); // Emerald
        softBgColor = const Color(0xFFECFDF5);
        defaultIcon = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        accentColor = const Color(0xFFEF4444); // Crimson
        softBgColor = const Color(0xFFFEF2F2);
        defaultIcon = Icons.error_rounded;
        break;
      case ToastType.warning:
        accentColor = const Color(0xFFF59E0B); // Amber
        softBgColor = const Color(0xFFFFFBEB);
        defaultIcon = Icons.warning_rounded;
        break;
      case ToastType.info:
        accentColor = AppColors.primary; // CarrierDirect Orange
        softBgColor = const Color(0xFFFFF1EB);
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
        softBgColor: softBgColor,
        icon: displayIcon,
        actionLabel: actionLabel,
        onAction: onAction,
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
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2200),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: ToastType.success,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    String? title,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2600),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: ToastType.error,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    String? title,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2200),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: ToastType.info,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    String? title,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: ToastType.warning,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }
}

class _TopToastWidget extends StatefulWidget {
  final String? title;
  final String message;
  final Color accentColor;
  final Color softBgColor;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopToastWidget({
    this.title,
    required this.message,
    required this.accentColor,
    required this.softBgColor,
    required this.icon,
    this.actionLabel,
    this.onAction,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget>
    with SingleTickerProviderStateMixin {
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
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! < 0) {
                  _dismiss();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                      blurRadius: 20,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: widget.title != null
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    // Soft tinted icon badge without border
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: widget.softBgColor,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Center(
                        child: Icon(
                          widget.icon,
                          color: widget.accentColor,
                          size: 19,
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
                                color: Color(0xFF0F172A),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2.5),
                            Text(
                              widget.message,
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 12.2,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                              ),
                            ),
                          ] else ...[
                            Text(
                              widget.message,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.actionLabel != null &&
                        widget.onAction != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          widget.onAction?.call();
                          _dismiss();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: widget.softBgColor,
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            widget.actionLabel!,
                            style: TextStyle(
                              color: widget.accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    // Clean borderless dismiss button
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _dismiss,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
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
