/// BoundingBoxPainter is a CustomPainter used to draw bounding boxes and labels
/// on top of the camera preview for detected objects.
///
/// Jewei built it such that it takes a list of detection maps, where each map contains normalized
/// coordinates (x, y, width, height) and a label. It converts these normalized
/// values to actual positions based on the current canvas size => draws the bounding boxes
/// along with a label background and text.
import 'package:flutter/material.dart';

class BoundingBoxPainter extends CustomPainter {
  /// A list of detection maps.
  /// Each detection should include:
  /// - 'x': normalized center x-coordinate.
  /// - 'y': normalized center y-coordinate.
  /// - 'width': normalized width of the bounding box.
  /// - 'height': normalized height of the bounding box.
  /// - 'label': label for the detected object.
  final List<Map<String, dynamic>> detections;

  /// Constructor for [BoundingBoxPainter].
  BoundingBoxPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    // Start a stopwatch for debugging to measure painting time.( maybe we include this in the presentation?)
    Stopwatch paintStopwatch = Stopwatch()..start();

    // Define what paint style we are using to draw the bounding boxes for the detected objects.
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.greenAccent;

    // Iterate through each detection and draw its bounding box and label.
    detections.forEach((detection) {
      // Retrieve normalized detection values.
      double x = detection['x'];
      double y = detection['y'];
      double width = detection['width'];
      double height = detection['height'];
      String label = detection['label'];

      // Create a rectangle from the center coordinates.
      final rect = Rect.fromCenter(
        center: Offset(x * size.width, y * size.height),
        width: width * size.width,
        height: height * size.height,
      );

      // Draw the bounding box on the canvas.
      canvas.drawRect(rect, paint);

      // Drawing the label text using TextPainter.
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: const Color.fromARGB(255, 255, 54, 54),
            fontSize: 16,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Define a background rectangle behind the label for better UI
      final backgroundRect = Rect.fromLTWH(
        rect.left,
        rect.top - 20,
        textPainter.width + 6,
        textPainter.height + 4,
      );

      // Create a paint object for the background.
      final bgPaint = Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.fill;

      // Draw the background rectangle.
      canvas.drawRect(backgroundRect, bgPaint);
      // Paint the label text on top of the background.
      textPainter.paint(canvas, Offset(rect.left + 3, rect.top - 18));
    });

    // Stop the stopwatch and print the time taken for painting (for debugging).
    paintStopwatch.stop();
    print("🎯🎯🎯Box painting took: ${paintStopwatch.elapsedMilliseconds} ms");
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
