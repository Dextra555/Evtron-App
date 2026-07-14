import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LargeChargerMarker {
  static final Map<String, BitmapDescriptor> _cache = {};

  static Future<BitmapDescriptor> createLargeMarker({
    required int available,
    required int total,
    required bool isAvailable,
    String status = 'available',
    bool hasFault = false,
    bool hasOffline = false,
  }) async
  {
    final cacheKey = '${available}_${total}_${isAvailable}_${status}_${hasFault}_${hasOffline}';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const Size size = Size(85, 110);

    Color markerColor;

    if (hasFault || hasOffline) {
      markerColor = Colors.orange;
    }
    // Check if station is busy even though chargers are available
    else if (status == 'busy' && available > 0) {
      markerColor = Colors.grey.shade600; // Grey - chargers available but station is busy
    }
    // Check if any charger is actually available and the station should be treated as available
    else if (available > 0 && isAvailable) {
      markerColor = const Color(0xFF1DBA2C); // Green - has available chargers
    }
    // No available chargers
    else {
      markerColor = Colors.red; // Red - no chargers available
    }

    // Shadow - adjusted coordinates
    canvas.drawOval(
      const Rect.fromLTWH(25, 95, 35, 7),
      Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    final Paint pinPaint = Paint()
      ..color = markerColor
      ..style = PaintingStyle.fill;

    final Path pinPath = Path();

    // Pin shape - all coordinates adjusted proportionally (about 65%)
    pinPath.moveTo(42.5, 5);

    pinPath.cubicTo(
      16.25,
      5,
      6.5,
      26,
      13,
      51,
    );

    pinPath.cubicTo(
      18.2,
      70,
      31.2,
      83,
      42.5,
      100,
    );

    pinPath.cubicTo(
      53.8,
      83,
      66.8,
      70,
      72,
      51,
    );

    pinPath.cubicTo(
      78.5,
      26,
      68.75,
      5,
      42.5,
      5,
    );

    pinPath.close();

    canvas.drawPath(pinPath, pinPaint);

    // Top rounded area
    canvas.drawCircle(
      const Offset(42.5, 38),
      27,
      pinPaint,
    );

    /// FUEL PUMP ICON - adjusted coordinates
    final Paint whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Main body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(29, 27, 18, 27),
        const Radius.circular(3),
      ),
      whitePaint,
    );

    // Display cutout
    canvas.drawRect(
      const Rect.fromLTWH(32, 31, 12, 7),
      Paint()..color = markerColor,
    );

    // Bottom stand
    canvas.drawRect(
      const Rect.fromLTWH(26, 60, 28, 3),
      whitePaint,
    );

    /// Hose - adjusted coordinates
    final hosePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final hosePath = Path()
      ..moveTo(47, 38)
      ..quadraticBezierTo(58, 39, 58, 51)
      ..lineTo(58, 58)
      ..quadraticBezierTo(58, 66, 52, 66);

    canvas.drawPath(hosePath, hosePaint);

    // Nozzle
    canvas.drawLine(
      const Offset(52, 66),
      const Offset(56, 62),
      hosePaint,
    );

    /// COUNT BADGE - adjusted coordinates
    if (available > 0) {
      // Badge shadow
      canvas.drawCircle(
        const Offset(62, 18),
        12,
        Paint()
          ..color = Colors.black.withOpacity(.15)
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.normal,
            2,
          ),
      );

      // White badge
      canvas.drawCircle(
        const Offset(61, 17),
        12,
        Paint()..color = Colors.white,
      );

      // Border
      canvas.drawCircle(
        const Offset(61, 17),
        12,
        Paint()
          ..color = markerColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: '$available',
          style: TextStyle(
            color: markerColor,
            fontSize: available > 9 ? 10 : 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(
          61 - textPainter.width / 2,
          17 - textPainter.height / 2,
        ),
      );
    }

    final image = await recorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );

    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData != null) {
      final marker = BitmapDescriptor.fromBytes(
        byteData.buffer.asUint8List(),
      );

      _cache[cacheKey] = marker;
      return marker;
    }

    return BitmapDescriptor.defaultMarker;
  }

  static void clearCache() {
    _cache.clear();
  }
}

