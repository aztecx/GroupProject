import 'package:flutter/material.dart';

/// BoundingBoxPainter renders object detection results as visual overlays.
///
/// This custom painter draws:
/// - Rectangular bounding boxes around detected objects
/// - Labels identifying each object with its class name
/// - Semi-transparent backgrounds behind labels for better visibility
///
/// The painter takes normalized coordinates (0-1) from object detection
/// results and scales them to the actual canvas dimensions for display.
/// While primarily intended for debugging and development, these visual
/// indicators can also help partially sighted users or assistants.
class BoundingBoxPainter extends CustomPainter {
  /// List of detected objects with their coordinates and labels.
  final List<Map<String, dynamic>> detections;

  BoundingBoxPainter(this.detections);

  /// Paints the bounding boxes and labels on the canvas.
  ///
  /// For each detection, this method:
  /// 1. Converts normalized coordinates to canvas coordinates
  /// 2. Draws a rectangular box around the detected object
  /// 3. Creates a semi-transparent background for the label
  /// 4. Renders the object label (class name) above the box
  ///
  /// Parameters:
  ///   canvas: The canvas to draw on
  ///   size: The size of the canvas (typically matches the camera preview)
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.greenAccent;

    detections.forEach((detection) {
      // Convert normalized coordinates (0-1) to canvas coordinates
      double x = detection['x']*size.width;
      double y = detection['y']*size.height;
      double width = detection['width']*size.width;
      double height = detection['height']*size.height;
      String label = detection['label'];
      // print("2️⃣boundingbox ${x*size.width}, ${y*size.height}, ${width*size.width}, ${height*size.height}");

      final rect = Rect.fromCenter(
        center: Offset(x, y),
        width: width,
        height: height,
      );
      canvas.drawRect(rect, paint);

      // Draw label background
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: const Color.fromARGB(255, 255, 54, 54), fontSize: 16),
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
  }

  /// Determines whether the painter should repaint when new detections arrive.
  ///
  /// This always returns true to ensure the bounding boxes update with every
  /// new set of detection results, which is necessary for real-time display
  /// of moving objects.
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
