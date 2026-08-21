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
    int inUse = 0,
    int fault = 0,
    int offline = 0,
  }) async {
    print('🎨 Creating marker with:');
    print('   Available: $available');
    print('   Total: $total');
    print('   isAvailable: $isAvailable');
    print('   status: $status');
    print('   hasFault: $hasFault');
    print('   hasOffline: $hasOffline');

    final cacheKey = '${available}_${total}_${isAvailable}_${status}_${hasFault}_${hasOffline}_${inUse}_${fault}_${offline}';

    if (_cache.containsKey(cacheKey)) {
      print('✅ Using cached marker');
      return _cache[cacheKey]!;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const Size size = Size(150, 240);
    canvas.scale(1.5);

    Color markerColor;

    if (available > 0) {
      markerColor = const Color(0xFF1DBA2C);
    } else if (inUse > 0) {
      markerColor = Colors.blue;
    } else if (fault > 0 && fault == total && available == 0 && inUse == 0) {
      markerColor = Colors.red;
    } else if (offline > 0 && offline == total && available == 0 && inUse == 0) {
      markerColor = Colors.grey.shade600;
    } else if ((offline > 0 || fault > 0) && available == 0 && inUse == 0) {
      markerColor = Colors.grey.shade600;
    } else if (hasFault || hasOffline) {
      markerColor = Colors.grey.shade600;
    } else if (status == 'busy' && available > 0) {
      markerColor = Colors.orange;
    } else if (available > 0 && isAvailable) {
      markerColor = const Color(0xFF1DBA2C);
    } else {
      markerColor = Colors.blue;
    }

    print('   Marker Color: $markerColor');

    canvas.drawOval(
      const Rect.fromLTWH(25, 125, 35, 7),
      Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    final countText = '$available/$total';
    final boxWidth = 62.0;
    final boxHeight = 26.0;
    final boxX = 42.5 - (boxWidth / 2);
    final boxY = 0.0;

    print('   Box Text: $countText');

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(boxX + 1, boxY + 1, boxWidth, boxHeight),
        const Radius.circular(5),
      ),
      Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(boxX, boxY, boxWidth, boxHeight),
        const Radius.circular(5),
      ),
      Paint()..color = Colors.white,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(boxX, boxY, boxWidth, boxHeight),
        const Radius.circular(5),
      ),
      Paint()
        ..color = markerColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: countText,
        style: TextStyle(
          color: markerColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(
        42.5 - textPainter.width / 2,
        boxY + (boxHeight - textPainter.height) / 2,
      ),
    );

    final Paint pinPaint = Paint()
      ..color = markerColor
      ..style = PaintingStyle.fill;

    final Path pinPath = Path();

    pinPath.moveTo(42.5, 28);

    pinPath.cubicTo(
      16.25,
      28,
      6.5,
      49,
      13,
      74,
    );

    pinPath.cubicTo(
      18.2,
      93,
      31.2,
      106,
      42.5,
      123,
    );

    pinPath.cubicTo(
      53.8,
      106,
      66.8,
      93,
      72,
      74,
    );

    pinPath.cubicTo(
      78.5,
      49,
      68.75,
      28,
      42.5,
      28,
    );

    pinPath.close();

    canvas.drawPath(pinPath, pinPaint);

    canvas.drawCircle(
      const Offset(42.5, 61),
      27,
      pinPaint,
    );

    final Paint whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(29, 50, 18, 27),
        const Radius.circular(3),
      ),
      whitePaint,
    );

    canvas.drawRect(
      const Rect.fromLTWH(32, 54, 12, 7),
      Paint()..color = markerColor,
    );

    canvas.drawRect(
      const Rect.fromLTWH(26, 83, 28, 3),
      whitePaint,
    );

    final hosePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final hosePath = Path()
      ..moveTo(47, 61)
      ..quadraticBezierTo(58, 62, 58, 74)
      ..lineTo(58, 81)
      ..quadraticBezierTo(58, 89, 52, 89);

    canvas.drawPath(hosePath, hosePaint);

    canvas.drawLine(
      const Offset(52, 89),
      const Offset(56, 85),
      hosePaint,
    );


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
      print('✅ Marker created and cached');
      return marker;
    }

    print('⚠️ Failed to create marker, using default');
    return BitmapDescriptor.defaultMarker;
  }

  static void clearCache() {
    _cache.clear();
  }
}


