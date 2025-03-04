import 'dart:async';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;
import 'package:flutter_tts/flutter_tts.dart';

class YoloService {
  late tfl.Interpreter _interpreter;
  List<String> _labels = [];
  final FlutterTts _flutterTts = FlutterTts();
  // Input image size used for the model.
  final int _inputSize = 640;
  // Confidence threshold for detection.
  final double _confidenceThreshold = 0.2;
  // Set this flag to true if your model outputs normalized coordinates (0-1).
  // Set to false if it outputs absolute pixel values.
  final bool modelOutputsNormalized = true;

  // Loads the model and labels from assets.
  Future<void> loadModel() async {
    try {
      print("🔄 Checking if model file exists...");
      _interpreter = await tfl.Interpreter.fromAsset('assets/models/yolov8n_float16.tflite');
      print("✅ Model file exists!");

      // Load labels from the file.
      String labelsData = await rootBundle.loadString('assets/labels/coco_labels.txt');
      _labels = labelsData.split('\n').where((line) => line.trim().isNotEmpty).toList();
      print("✅ Labels Loaded: ${_labels.length} labels");
      print("✅ Model Loaded Successfully!");
    } catch (e) {
      print("❌ Error loading model: $e");
    }
  }

  // Runs inference on the given image and returns a list of detections.
  // Each detection is a map with normalized bounding box and detection info.
  Future<List<Map<String, dynamic>>> runModel(img.Image image) async {
    List<Map<String, dynamic>> detections = [];
    try {
      // Resize the image to the expected input size.
      img.Image resizedImage = img.copyResize(image, width: _inputSize, height: _inputSize);
      print("📊 Image Preprocessing Done!");

      // Prepare input tensor of shape [1, _inputSize, _inputSize, 3] with normalized RGB values.
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

      // Prepare output tensor.
      // The model returns a tensor of shape [1, 84, 8400].
      var output = List.generate(1, (_) =>
          List.generate(84, (_) =>
              List.filled(8400, 0.0)
          )
      );

      // Run the model.
      _interpreter.run(input, output);

      // Debug: print the output shape.
      print("📊 Model output shape: [${output.length}, ${output[0].length}, ${output[0][0].length}]");

      // Transpose output from [1,84,8400] to [1,8400,84]
      List<List<double>> transposedOutput = List.generate(8400, (_) => List.filled(84, 0.0));
      for (int i = 0; i < 84; i++) {
        for (int j = 0; j < 8400; j++) {
          transposedOutput[j][i] = output[0][i][j];
        }
      }
      print("📊 Transposed detections count: ${transposedOutput.length}");

      // Process each detection.
      for (var detection in transposedOutput) {
        // Ensure the detection has the expected 84 elements.
        if (detection.length != 84) continue;
        // First 4 values: bounding box (center_x, center_y, width, height)
        double cx = detection[0];
        double cy = detection[1];
        double boxWidth = detection[2];
        double boxHeight = detection[3];

        // Debug: print raw bounding box values.
        print("🔍 Raw bounding box: cx=$cx, cy=$cy, width=$boxWidth, height=$boxHeight");

        // If your model outputs absolute pixel values, normalize by _inputSize.
        double normalizedCx = modelOutputsNormalized ? cx : cx / _inputSize;
        double normalizedCy = modelOutputsNormalized ? cy : cy / _inputSize;
        double normalizedWidth = modelOutputsNormalized ? boxWidth : boxWidth / _inputSize;
        double normalizedHeight = modelOutputsNormalized ? boxHeight : boxHeight / _inputSize;

        // Debug: print the normalized bounding box values.
        print("🔍 Normalized bounding box: cx=$normalizedCx, cy=$normalizedCy, width=$normalizedWidth, height=$normalizedHeight");

        // Next 80 values: class scores.
        List<double> classScores = detection.sublist(4);
        // Find the maximum score and corresponding index.
        double maxScore = 0.0;
        int classIndex = -1;
        for (int i = 0; i < classScores.length; i++) {
          if (classScores[i] > maxScore) {
            maxScore = classScores[i];
            classIndex = i;
          }
        }

        // Use the detection if the confidence is above the threshold.
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

      // If there are detections, speak out the unique labels.
      if (detections.isNotEmpty) {
        String speech = detections.map((det) => det['label']).toSet().join(', ');
        await _flutterTts.speak("Detected: $speech");
      }
    } catch (e) {
      print("❌ Error running model: $e");
    }
    return detections;
  }
}









// import 'dart:typed_data';
// import 'dart:async';
// import 'package:flutter/services.dart';
// import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
// import 'package:image/image.dart' as img;
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:flutter/material.dart';
//
// class YoloService {
//   static const String modelPath = 'assets/models/yolov8n_float16.tflite'; // Ensure correct model
//   static const String labelsPath = 'assets/labels/coco_labels.txt';
//   static const int inputSize = 640;
//   static const double confidenceThreshold = 0.3;
//   static const double nmsThreshold = 0.5;
//
//   late tfl.Interpreter _interpreter;
//   late List<String> _labels;
//   final FlutterTts _flutterTts = FlutterTts();
//   bool _isModelLoaded = false;
//
//   Future<void> loadModel() async {
//     try {
//       _interpreter = await tfl.Interpreter.fromAsset(modelPath);
//       _labels = await _loadLabels();
//       _isModelLoaded = true;
//       print("✅ Model Expected Input Shape: ${_interpreter.getInputTensor(0).shape}");
//       print("✅ Model Expected Output Shape: ${_interpreter.getOutputTensor(0).shape}");
//     } catch (e) {
//       print("❌ Model Error: $e");
//     }
//   }
//
//   Future<List<String>> _loadLabels() async {
//     final rawLabels = await rootBundle.loadString(labelsPath);
//     return rawLabels.split('\n').map((e) => e.trim()).toList();
//   }
//
//   Future<List<Map<String, dynamic>>> runModel(img.Image image) async {
//     if (!_isModelLoaded) return [];
//
//     try {
//       final input = _preprocessImage(image);
//       final reshapedInput = input.buffer.asFloat32List(); // Ensure correct format
//       final output = List.generate(1, (_) => List.generate(84, (_) => List.filled(8400, 0.0)));
//
//       _interpreter.run(reshapedInput.reshape([1, 640, 640, 3]), output);
//       return _processOutput(output[0]);
//     } catch (e) {
//       print("❌ Inference Error: $e");
//       return [];
//     }
//   }
//
//
//   Float32List _preprocessImage(img.Image image) {
//     final resized = img.copyResize(image, width: inputSize, height: inputSize);
//     final Float32List floatData = Float32List(1 * inputSize * inputSize * 3);
//
//     int pixelIndex = 0;
//     for (int y = 0; y < inputSize; y++) {
//       for (int x = 0; x < inputSize; x++) {
//         final pixel = resized.getPixel(x, y);
//         floatData[pixelIndex++] = pixel.r / 255.0; // Normalize to [0,1]
//         floatData[pixelIndex++] = pixel.g / 255.0;
//         floatData[pixelIndex++] = pixel.b / 255.0;
//       }
//     }
//
//     return floatData;
//   }
//
//
//   List<Map<String, dynamic>> _processOutput(List<List<double>> output) {
//     final detections = <Map<String, dynamic>>[];
//
//     for (int i = 0; i < 8400; i++) {
//       final objectness = output[4][i];
//       if (objectness < 0.3) continue;
//
//       double maxScore = 0;
//       int classId = 0;
//       for (int j = 5; j < 84; j++) {
//         if (output[j][i] > maxScore) {
//           maxScore = output[j][i];
//           classId = j - 5;
//         }
//       }
//
//       final confidence = objectness * maxScore;
//       if (confidence < confidenceThreshold) continue;
//
//       if (classId >= _labels.length) {
//         print("⚠️ Warning: Invalid class ID $classId, defaulting to Unknown.");
//         classId = 0;
//       }
//
//       final cx = output[0][i];
//       final cy = output[1][i];
//       final w = output[2][i];
//       final h = output[3][i];
//
//       detections.add({
//         "x": (cx - w / 2) / inputSize,
//         "y": (cy - h / 2) / inputSize,
//         "width": w / inputSize,
//         "height": h / inputSize,
//         "label": _labels[classId],
//         "confidence": confidence
//       });
//
//       print("🎯 Detected: ${_labels[classId]} (${confidence.toStringAsFixed(2)})");
//     }
//
//     return _nonMaxSuppression(detections);
//   }
//
//   List<Map<String, dynamic>> _nonMaxSuppression(List<Map<String, dynamic>> detections) {
//     detections.sort((a, b) => b['confidence'].compareTo(a['confidence']));
//     final filtered = <Map<String, dynamic>>[];
//
//     while (detections.isNotEmpty) {
//       final current = detections.removeAt(0);
//       filtered.add(current);
//
//       detections.removeWhere((detection) {
//         final currentRect = _rectFromMap(current);
//         final detectionRect = _rectFromMap(detection);
//         return _iou(currentRect, detectionRect) > nmsThreshold;
//       });
//     }
//     return filtered;
//   }
//
//   Rect _rectFromMap(Map<String, dynamic> detection) {
//     return Rect.fromLTWH(
//       detection['x'],
//       detection['y'],
//       detection['width'],
//       detection['height'],
//     );
//   }
//
//   double _iou(Rect a, Rect b) {
//     final intersection = a.intersect(b);
//     final intersectionArea = intersection.width * intersection.height;
//     final unionArea = a.width * a.height + b.width * b.height - intersectionArea;
//     return intersectionArea / unionArea;
//   }
// }
