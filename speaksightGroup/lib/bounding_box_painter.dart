// lib/bounding_box_painter.dart
import 'package:flutter/material.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> detections;

  BoundingBoxPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    Stopwatch paintStopwatch = Stopwatch()..start();

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.greenAccent;

    detections.forEach((detection) {
      // Drawing logic for each detection
      double x = detection['x'];
      double y = detection['y'];
      double width = detection['width'];
      double height = detection['height'];
      String label = detection['label'];

      final rect = Rect.fromCenter(
        center: Offset(x * size.width, y * size.height),
        width: width * size.width,
        height: height * size.height,
      );
      canvas.drawRect(rect, paint);

      // Draw label background and text
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: Color.fromARGB(255, 255, 54, 54), fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final backgroundRect = Rect.fromLTWH(
        rect.left,
        rect.top - 20,
        textPainter.width + 6,
        textPainter.height + 4,
      );
      final bgPaint = Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.fill;
      canvas.drawRect(backgroundRect, bgPaint);
      textPainter.paint(canvas, Offset(rect.left + 3, rect.top - 18));
    });

    paintStopwatch.stop();
    print("🎯🎯🎯Box painting took: ${paintStopwatch.elapsedMilliseconds} ms");
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
