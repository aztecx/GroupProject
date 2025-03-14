// lib/yolo_service.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;
import 'package:flutter_tts/flutter_tts.dart';

class YoloService {
  late tfl.Interpreter _interpreter;
  List<String> _labels = [];
  final FlutterTts _flutterTts = FlutterTts();
  // Make _inputSize mutable so it can be updated.
  int _inputSize = 640;
  // Confidence threshold for detection.
  final double _confidenceThreshold = 0.5;
  // Set this flag to true if your model outputs normalized coordinates (0-1).
  final bool modelOutputsNormalized = true;

  Future<void> loadModel() async {
    try {
      print("🔄 Checking if model file exists...");
      _interpreter = await tfl.Interpreter.fromAsset('assets/models/yolov8n_float16.tflite');
      print("✅ Model file exists!");

      // Check the model's input tensor shape.
      var inputShape = _interpreter.getInputTensor(0).shape;
      print("Model input shape: $inputShape");
      // Typically the input shape is [1, width, height, 3].
      if (inputShape.length >= 3) {
        int modelInputSize = inputShape[1]; // width
        // If the model supports a lower input size than 640, update _inputSize.
        if (modelInputSize < 640) {
          _inputSize = modelInputSize;
          print("Using lower input size from model: $_inputSize");
        } else {
          print("Using default input size: $_inputSize");
        }
      }

      String labelsData = await rootBundle.loadString('assets/labels/coco_labels.txt');
      _labels = labelsData.split('\n').where((line) => line.trim().isNotEmpty).toList();
      print("✅ Labels Loaded: ${_labels.length} labels");
      print("✅ Model Loaded Successfully!");
    } catch (e) {
      print("❌ Error loading model: $e");
    }
  }

  Future<List<Map<String, dynamic>>> runModel(img.Image image) async {
    List<Map<String, dynamic>> detections = [];
    try {
      // Resize the image to the expected input size.
      img.Image resizedImage = img.copyResize(image, width: _inputSize, height: _inputSize);
      print("📊 Image Preprocessing Done!");

      // Prepare input tensor: [1, _inputSize, _inputSize, 3]
      var input = List.generate(1, (_) =>
          List.generate(_inputSize, (i) =>
              List.generate(_inputSize, (j) =>
                  List.generate(3, (c) {
                    var pixelObj = resizedImage.getPixel(j, i);
                    int r = pixelObj.r.toInt();
                    int g = pixelObj.g.toInt();
                    int b = pixelObj.b.toInt();
                    if (c == 0) return r / 255.0;
                    if (c == 1) return g / 255.0;
                    return b / 255.0;
                  })
              )
          )
      );

      // Prepare output tensor: [1, 84, 8400]
      var output = List.generate(1, (_) =>
          List.generate(84, (_) =>
              List.filled(2100, 0.0)
          )
      );

      // Run the model.
      _interpreter.run(input, output);
      print("📊 Model output shape: [${output.length}, ${output[0].length}, ${output[0][0].length}]");

      // Transpose output from [1,84,8400] to [8400,84]
      List<List<double>> transposedOutput = List.generate(2100, (_) => List.filled(84, 0.0));
      for (int i = 0; i < 84; i++) {
        for (int j = 0; j < 2100; j++) {
          transposedOutput[j][i] = output[0][i][j];
        }
      }
      print("📊 Transposed detections count: ${transposedOutput.length}");

      // Process each detection.
      for (var detection in transposedOutput) {
        if (detection.length != 84) continue;
        double cx = detection[0];
        double cy = detection[1];
        double boxWidth = detection[2];
        double boxHeight = detection[3];

        double normalizedCx = modelOutputsNormalized ? cx : cx / _inputSize;
        double normalizedCy = modelOutputsNormalized ? cy : cy / _inputSize;
        double normalizedWidth = modelOutputsNormalized ? boxWidth : boxWidth / _inputSize;
        double normalizedHeight = modelOutputsNormalized ? boxHeight : boxHeight / _inputSize;

        // Get class scores.
        List<double> classScores = detection.sublist(4);
        double maxScore = 0.0;
        int classIndex = -1;
        for (int i = 0; i < classScores.length; i++) {
          if (classScores[i] > maxScore) {
            maxScore = classScores[i];
            classIndex = i;
          }
        }

        if (maxScore >= _confidenceThreshold) {
          String label = (classIndex < _labels.length) ? _labels[classIndex] : "Unknown";
          detections.add({
            'x': normalizedCx,
            'y': normalizedCy,
            'width': normalizedWidth,
            'height': normalizedHeight,
            'label': label,
            'confidence': maxScore,
          });
          print("🎯 Detected: $label with confidence $maxScore");
        }
      }

      // Apply Non-Maximum Suppression to filter out overlapping detections.
      double nmsThreshold = 0.5; // Adjust this threshold as needed.
      detections = _nonMaxSuppression(detections, nmsThreshold);

      // Speak out unique labels if there are detections.
      if (detections.isNotEmpty) {
        String speech = detections.map((det) => det['label']).toSet().join(', ');
        await _flutterTts.speak("Detected: $speech");
      }
    } catch (e) {
      print("❌ Error running model: $e");
    }
    return detections;
  }

  // Helper: Calculate Intersection over Union (IoU) between two detections.
  double _calculateIoU(Map<String, dynamic> a, Map<String, dynamic> b) {
    // Convert center-based coordinates to box corners.
    double ax1 = a['x'] - a['width'] / 2;
    double ay1 = a['y'] - a['height'] / 2;
    double ax2 = a['x'] + a['width'] / 2;
    double ay2 = a['y'] + a['height'] / 2;

    double bx1 = b['x'] - b['width'] / 2;
    double by1 = b['y'] - b['height'] / 2;
    double bx2 = b['x'] + b['width'] / 2;
    double by2 = b['y'] + b['height'] / 2;

    double interX1 = ax1 > bx1 ? ax1 : bx1;
    double interY1 = ay1 > by1 ? ay1 : by1;
    double interX2 = ax2 < bx2 ? ax2 : bx2;
    double interY2 = ay2 < by2 ? ay2 : by2;

    double interArea = 0;
    if (interX2 > interX1 && interY2 > interY1) {
      interArea = (interX2 - interX1) * (interY2 - interY1);
    }
    double areaA = (ax2 - ax1) * (ay2 - ay1);
    double areaB = (bx2 - bx1) * (by2 - by1);
    double unionArea = areaA + areaB - interArea;
    return unionArea > 0 ? interArea / unionArea : 0;
  }

  // Helper: Non-Maximum Suppression to filter overlapping detections.
  List<Map<String, dynamic>> _nonMaxSuppression(List<Map<String, dynamic>> detections, double threshold) {
    // Sort detections by descending confidence.
    detections.sort((a, b) => b['confidence'].compareTo(a['confidence']));
    List<Map<String, dynamic>> filtered = [];
    while (detections.isNotEmpty) {
      var best = detections.removeAt(0);
      filtered.add(best);
      detections.removeWhere((d) {
        double iou = _calculateIoU(best, d);
        return iou > threshold;
      });
    }
    return filtered;
  }
}
