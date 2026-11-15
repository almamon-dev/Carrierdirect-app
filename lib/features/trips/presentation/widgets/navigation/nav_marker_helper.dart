import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Helper utility for creating navigation map marker bitmaps (chevrons, pins, route badges).
class NavMarkerHelper {
  const NavMarkerHelper._();

  /// Renders a dynamic vehicle chevron marker pointing forward with glowing aura.
  static Future<Uint8List> createNavigationChevronMarker({
    Color chevronColor = const Color(0xFF2563EB),
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const double size = 120.0;
    const center = Offset(size / 2, size / 2);

    // Glowing aura
    final glow = Paint()
      ..color = chevronColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 52, glow);

    // Translucent forward radar cone
    final radarPaint = Paint()
      ..shader = ui.Gradient.radial(center, 50, [
        chevronColor.withValues(alpha: 0.35),
        chevronColor.withValues(alpha: 0.0),
      ])
      ..style = PaintingStyle.fill;
    final radarPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx - 34, center.dy - 52)
      ..arcToPoint(
        Offset(center.dx + 34, center.dy - 52),
        radius: const Radius.circular(52),
        clockwise: true,
      )
      ..close();
    canvas.drawPath(radarPath, radarPaint);

    // Drop shadow
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.26)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawCircle(center.translate(0, 3), 30, shadow);

    // White disc
    final whiteDisc = Paint()..color = Colors.white;
    canvas.drawCircle(center, 30, whiteDisc);

    // Navigation Chevron
    final arrowPaint = Paint()
      ..color = chevronColor
      ..style = PaintingStyle.fill;
    final arrowPath = Path()
      ..moveTo(center.dx, center.dy - 20)
      ..lineTo(center.dx + 16, center.dy + 15)
      ..lineTo(center.dx, center.dy + 7)
      ..lineTo(center.dx - 16, center.dy + 15)
      ..close();
    canvas.drawPath(arrowPath, arrowPaint);

    // Center accent line
    final accentLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(center.dx, center.dy - 17),
      Offset(center.dx, center.dy + 7),
      accentLine,
    );

    final pic = recorder.endRecording();
    final img = await pic.toImage(size.toInt(), size.toInt());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  /// Renders a crisp Google Maps-style location marker with icon and 4px radius label badge.
  static Future<Uint8List> createCustomLocationMarker({
    required String label,
    required Color badgeColor,
    required IconData iconData,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const double w = 140.0;
    const double h = 90.0;
    const double cx = w / 2;

    // 1. Floating pill badge on top
    final pillRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(cx, 16), width: 118, height: 26),
      const Radius.circular(4.0), // 4px border radius
    );

    // Drop shadow under pill
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawRRect(pillRRect.shift(const Offset(0, 2)), shadowPaint);

    // Pill background
    final pillPaint = Paint()..color = badgeColor;
    canvas.drawRRect(pillRRect, pillPaint);

    // Pill white border
    final pillBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawRRect(pillRRect, pillBorder);

    // Pill Icon + Text
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: String.fromCharCode(iconData.codePoint),
            style: TextStyle(
              fontSize: 13.5,
              fontFamily: iconData.fontFamily,
              package: iconData.fontPackage,
              color: Colors.white,
            ),
          ),
          const TextSpan(text: '  '),
          TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, 16 - textPainter.height / 2),
    );

    // 2. Teardrop Pin pointing directly downward
    const double pinCenterY = 48.0;
    const double pinRadius = 14.5;
    const double pinTipY = 82.0;

    // Ground shadow
    final groundShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(cx, pinTipY), width: 18, height: 5),
      groundShadow,
    );

    // Pin shape
    final pinPath = Path()
      ..moveTo(cx, pinTipY)
      ..cubicTo(
        cx - 3,
        pinTipY - 10,
        cx - pinRadius,
        pinCenterY + 8,
        cx - pinRadius,
        pinCenterY,
      )
      ..arcToPoint(
        const Offset(cx + pinRadius, pinCenterY),
        radius: const Radius.circular(pinRadius),
        clockwise: true,
      )
      ..cubicTo(
        cx + pinRadius,
        pinCenterY + 8,
        cx + 3,
        pinTipY - 10,
        cx,
        pinTipY,
      )
      ..close();

    final pinPaint = Paint()..color = badgeColor;
    canvas.drawPath(pinPath, pinPaint);

    final whitePinBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(pinPath, whitePinBorder);

    // Inner white circle inside pin
    final whiteCircle = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(cx, pinCenterY), 9.0, whiteCircle);

    // Inner icon inside pin
    final innerIconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: 11.5,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          color: badgeColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    innerIconPainter.paint(
      canvas,
      Offset(
        cx - innerIconPainter.width / 2,
        pinCenterY - innerIconPainter.height / 2,
      ),
    );

    final pic = recorder.endRecording();
    final img = await pic.toImage(w.toInt(), h.toInt());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  /// Creates a crisp on-map route badge (e.g. "Fastest" or "+7 min") with 4px border radius.
  static Future<Uint8List> createRouteBadgeIcon({
    required String text,
    required bool isSelected,
    Color activeColor = const Color(0xFF2563EB),
    Color textColor = const Color(0xFF0F172A),
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const double w = 110.0;
    const double h = 34.0;
    const double cx = w / 2;
    const double cy = h / 2;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(cx, cy), width: w - 8, height: 26),
      const Radius.circular(4.0), // 4px border radius
    );

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawRRect(rrect.shift(const Offset(0, 1.5)), shadowPaint);

    // Background
    final bgPaint = Paint()..color = isSelected ? activeColor : Colors.white;
    canvas.drawRRect(rrect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = isSelected ? Colors.white : const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRRect(rrect, borderPaint);

    // Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: isSelected ? Colors.white : textColor,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );

    final pic = recorder.endRecording();
    final img = await pic.toImage(w.toInt(), h.toInt());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  /// Creates a Google Maps-style multi-line route pill badge (e.g. "🚗 57 min\n22.6 km")
  /// exactly matching the official Google Maps navigation UI.
  static Future<Uint8List> createGoogleMapsPillBadge({
    required String duration,
    required String distance,
    required bool isSelected,
    Color activeColor = const Color(0xFF1A73E8),
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const double w = 150.0;
    const double h = 80.0;
    const double cx = w / 2;
    const double cardH = 54.0;
    const double cardW = 126.0;

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(cx, 30), width: cardW, height: cardH),
      const Radius.circular(8.0),
    );

    // 1. Drop shadow under card
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isSelected ? 0.35 : 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawRRect(cardRect.shift(const Offset(0, 3)), shadowPaint);

    // 2. Downward speech arrow pointer
    final arrowPath = Path()
      ..moveTo(cx - 7, 57)
      ..lineTo(cx + 7, 57)
      ..lineTo(cx, 68)
      ..close();
    final arrowPaint = Paint()
      ..color = isSelected ? activeColor : Colors.white;
    canvas.drawPath(arrowPath, arrowPaint);

    if (!isSelected) {
      final arrowBorder = Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(arrowPath, arrowBorder);
    }

    // 3. Main card background
    final bgPaint = Paint()..color = isSelected ? activeColor : Colors.white;
    canvas.drawRRect(cardRect, bgPaint);

    // 4. Card border
    final borderPaint = Paint()
      ..color = isSelected ? Colors.white : const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.5;
    canvas.drawRRect(cardRect, borderPaint);

    // 5. Line 1: Duration with Car Icon
    final durationPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: String.fromCharCode(Icons.directions_car_rounded.codePoint),
            style: TextStyle(
              fontSize: 14.0,
              fontFamily: Icons.directions_car_rounded.fontFamily,
              package: Icons.directions_car_rounded.fontPackage,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
          const TextSpan(text: '  '),
          TextSpan(
            text: duration,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              fontFamily: 'Roboto',
              color: isSelected ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    durationPainter.paint(
      canvas,
      Offset(cx - durationPainter.width / 2, 12),
    );

    // 6. Line 2: Distance
    final distPainter = TextPainter(
      text: TextSpan(
        text: distance,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
          color: isSelected ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF64748B),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    distPainter.paint(
      canvas,
      Offset(cx - distPainter.width / 2, 34),
    );

    final pic = recorder.endRecording();
    final img = await pic.toImage(w.toInt(), h.toInt());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  /// Creates the Driver vehicle disc with glowing halo and floating speech bubble callout
  /// e.g. "You (Driver)\n• To Pickup: 8.5 km • 18 min"
  static Future<Uint8List> createDriverWithCalloutMarker({
    String title = 'You (Driver)',
    String subtitle = 'To Pickup: 8.5 km • 18 min',
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const double w = 240.0;
    const double h = 120.0;
    const double cx = w / 2;
    const double cardW = 190.0;
    const double cardH = 46.0;

    // 1. Callout speech bubble card at the top
    final cardRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(cx, 26), width: cardW, height: cardH),
      const Radius.circular(8.0),
    );

    // Drop shadow under card
    final cardShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawRRect(cardRRect.shift(const Offset(0, 2)), cardShadow);

    // Card white background
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawRRect(cardRRect, whitePaint);

    // Card subtle border
    final borderPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(cardRRect, borderPaint);

    // Downward speech triangle connecting card to vehicle disc
    final arrowPath = Path()
      ..moveTo(cx - 6, 49)
      ..lineTo(cx + 6, 49)
      ..lineTo(cx, 56)
      ..close();
    canvas.drawPath(arrowPath, whitePaint);
    final arrowBorder = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(arrowPath, arrowBorder);

    // Line 1: "You (Driver)"
    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 12.0,
          fontWeight: FontWeight.w800,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    titlePainter.paint(
      canvas,
      Offset(cx - cardW / 2 + 14, 10),
    );

    // Line 2: Green Dot + "To Pickup: 8.5 km • 18 min"
    final dotPaint = Paint()..color = const Color(0xFF16A34A);
    canvas.drawCircle(Offset(cx - cardW / 2 + 18, 35), 3.5, dotPaint);

    final subtitlePainter = TextPainter(
      text: TextSpan(
        text: subtitle,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    subtitlePainter.paint(
      canvas,
      Offset(cx - cardW / 2 + 26, 29),
    );

    // 2. Blue Driver vehicle marker at bottom (center cx, cy 88)
    const double carCy = 88.0;

    // Glowing halo
    final haloPaint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(cx, carCy), 28, haloPaint);

    // White disc with shadow
    final discShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawCircle(const Offset(cx, carCy + 1), 19, discShadow);
    canvas.drawCircle(const Offset(cx, carCy), 19, whitePaint);

    // Blue vehicle circle
    final bluePaint = Paint()..color = const Color(0xFF2563EB);
    canvas.drawCircle(const Offset(cx, carCy), 15.5, bluePaint);

    // Truck icon
    final truckPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.local_shipping_rounded.codePoint),
        style: TextStyle(
          fontSize: 15.0,
          fontFamily: Icons.local_shipping_rounded.fontFamily,
          package: Icons.local_shipping_rounded.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    truckPainter.paint(
      canvas,
      Offset(cx - truckPainter.width / 2, carCy - truckPainter.height / 2),
    );

    final pic = recorder.endRecording();
    final img = await pic.toImage(w.toInt(), h.toInt());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  /// Creates a teardrop pin with a connected capsule label badge beside it
  /// e.g. [Green Pin] + [Pickup]  OR  [Red Pin] + [Delivery]
  static Future<Uint8List> createPinWithCapsuleBadge({
    required Color pinColor,
    required String badgeText,
    String locationName = '',
    IconData icon = Icons.inventory_2_rounded,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Inner tag text (e.g. "Pickup" or "Delivery")
    final badgeTagPainter = TextPainter(
      text: TextSpan(
        text: badgeText,
        style: TextStyle(
          color: pinColor,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bool hasLoc = locationName.trim().isNotEmpty;
    TextPainter? locPainter;
    if (hasLoc) {
      locPainter = TextPainter(
        text: TextSpan(
          text: locationName.trim(),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 11.0,
            fontWeight: FontWeight.w700,
            fontFamily: 'Roboto',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }

    const double capsuleLeft = 48.0;
    const double capsuleH = 28.0;
    const double capsuleTop = 10.0;

    final double capsuleW = hasLoc
        ? (badgeTagPainter.width + (locPainter?.width ?? 0) + 26.0)
            .clamp(70.0, 150.0)
        : (badgeTagPainter.width + 20.0);

    final double w = (capsuleLeft + capsuleW + 8.0).clamp(100.0, 200.0);
    const double h = 60.0;
    const double pinCx = 26.0;
    const double pinCy = 24.0;
    const double pinR = 17.0;
    const double pinTipY = 54.0;

    // 1. Ground shadow under pin tip
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(pinCx, pinTipY),
        width: 16,
        height: 5,
      ),
      shadowPaint,
    );

    // 2. Teardrop pin
    final pinPath = Path()
      ..moveTo(pinCx, pinTipY)
      ..cubicTo(
        pinCx - 3,
        pinTipY - 8,
        pinCx - pinR,
        pinCy + 8,
        pinCx - pinR,
        pinCy,
      )
      ..arcToPoint(
        const Offset(pinCx + pinR, pinCy),
        radius: const Radius.circular(pinR),
        clockwise: true,
      )
      ..cubicTo(
        pinCx + pinR,
        pinCy + 8,
        pinCx + 3,
        pinTipY - 8,
        pinCx,
        pinTipY,
      )
      ..close();

    final pinPaint = Paint()
      ..color = pinColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(pinPath, pinPaint);

    final pinStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(pinPath, pinStroke);

    // Inner icon inside pin
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 15.0,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(
      canvas,
      Offset(pinCx - iconPainter.width / 2, pinCy - iconPainter.height / 2),
    );

    // 3. Capsule label badge extending to the right
    final capsuleRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(capsuleLeft, capsuleTop, capsuleW, capsuleH),
      const Radius.circular(14.0),
    );

    // Capsule drop shadow
    final capShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawRRect(capsuleRRect.shift(const Offset(0, 1.5)), capShadow);

    // Capsule white background
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawRRect(capsuleRRect, whitePaint);

    // Capsule border
    final capBorder = Paint()
      ..color = pinColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(capsuleRRect, capBorder);

    if (hasLoc && locPainter != null) {
      badgeTagPainter.paint(
        canvas,
        const Offset(capsuleLeft + 10, capsuleTop + 6),
      );
      locPainter.paint(
        canvas,
        Offset(capsuleLeft + 14 + badgeTagPainter.width + 4, capsuleTop + 6.5),
      );
    } else {
      // Centered badge text when no location name
      badgeTagPainter.paint(
        canvas,
        Offset(
          capsuleLeft + (capsuleW - badgeTagPainter.width) / 2,
          capsuleTop + (capsuleH - badgeTagPainter.height) / 2,
        ),
      );
    }

    final pic = recorder.endRecording();
    final img = await pic.toImage(w.toInt(), h.toInt());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  /// Creates a floating route badge pill matching Google Maps
  /// e.g. [🚗 8.5 km • 18 min] (Blue) or [🚗 22 km • 39 min] (Green)
  static Future<Uint8List> createCapsuleRoutePill({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const double w = 150.0;
    const double h = 44.0;
    const double cx = w / 2;
    const double cy = h / 2;

    const double pillW = 138.0;
    const double pillH = 30.0;

    final pillRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(cx, cy), width: pillW, height: pillH),
      const Radius.circular(15.0),
    );

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawRRect(pillRRect.shift(const Offset(0, 2)), shadowPaint);

    // Background
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRRect(pillRRect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = borderColor ?? Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(pillRRect, borderPaint);

    // Car Icon + Text
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: String.fromCharCode(Icons.directions_car_rounded.codePoint),
            style: TextStyle(
              fontSize: 13.0,
              fontFamily: Icons.directions_car_rounded.fontFamily,
              package: Icons.directions_car_rounded.fontPackage,
              color: textColor,
            ),
          ),
          const TextSpan(text: '  '),
          TextSpan(
            text: text,
            style: TextStyle(
              color: textColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );

    final pic = recorder.endRecording();
    final img = await pic.toImage(w.toInt(), h.toInt());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }
}
