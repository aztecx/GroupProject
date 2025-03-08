import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;
import 'dart:typed_data';




class YoloService {
  final timers = <String, Stopwatch>{
    'base': Stopwatch(),
    'preprocess': Stopwatch(),
    'interpreter': Stopwatch(),
    'NMS': Stopwatch()
  };

  late tfl.Interpreter _interpreter;

  List<String> _labels = [];
  // Input image size used for the model.
  final int _inputSize = 320;
  // Confidence threshold for detection.
  final double _confidenceThreshold = 0.5;
  // Set this flag to true if your model outputs normalized coordinates (0-1).
  // Set to false if it outputs absolute pixel values.
  final bool modelOutputsNormalized = true;


  late int dx;
  late int dy;

  img.Image _resizedImage(img.Image image) {
    final originalWidth = image.width;
    final originalHeight = image.height;

    // calculating ratio
    final scale = min(_inputSize / originalWidth, _inputSize / originalHeight);
    final newWidth = (originalWidth * scale).toInt();
    final newHeight = (originalHeight * scale).toInt();

    dx = (_inputSize - newWidth) ~/ 2;
    dy = (_inputSize - newHeight) ~/ 2;

    final resized = img.copyResize(image, width: newWidth, height: newHeight);
    final padded = img.Image(width: _inputSize, height: _inputSize); // initialize a padded
    img.fill(padded, color: img.ColorRgb8(128, 128, 128)); // fill with grey pixel
    img.compositeImage(padded, resized, dstX: dx, dstY: dy); // paste the img in the center of the padded
    return padded;

  }

  // ⚠️ rbg normalization
  Float32List _prepareInput(img.Image image) {
    final input = Float32List(_inputSize * _inputSize * 3);
    int pixelIndex = 0;

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = image.getPixel(x, y);
        input[pixelIndex++] = pixel.r / 255.0;
        input[pixelIndex++] = pixel.g / 255.0;
        input[pixelIndex++] = pixel.b / 255.0;
      }
    }
    return input;
  }

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


      var inputTensors = _interpreter.getInputTensors();
      print("Input tensor type: ${inputTensors[0].type}");
      print("Input tensor shape: ${inputTensors[0].shape}");

    } catch (e) {
      print("❌ Error loading model: $e");
    }
  }

  Future<List<Map<String, dynamic>>> runModel(img.Image image) async {
    List<Map<String, dynamic>> detections = [];
    try {

      // ⚠️修改：改用保持比例的缩放（具体实现在上面）
      timers['base']?.start();
      timers['preprocess']?.start();
      timers['interpreter']?.start();
      timers['NMS']?.start();

      timers['base']?.stop();
      final processedImage = _resizedImage(image);
      final input = _prepareInput(processedImage);
      // print("📊 Image Preprocessing Done!");

      timers['preprocess']?.stop();

      // ⚠️内存溢出问题，很可能是由output这里引发的
      final output = List<List<List<double>>>.generate(
        1,
            (_) => List<List<double>>.generate(84, (_) => List<double>.filled(2100, 0.0, growable: false),
            growable: false),
      );

      _interpreter.run(input.buffer, output);
      // Debug: print the output shape.
      // print("📊 Model output shape: [${output.length}, ${output[0].length}, ${output[0][0].length}]");
      timers['interpreter']?.stop();

// Transpose output from [1,84,8400] to [1,8400,84]
      List<List<double>> transposedOutput = List.generate(2100, (_) => List.filled(84, 0.0));
      for (int i = 0; i < 84; i++) {
        for (int j = 0; j < 2100; j++) {
          transposedOutput[j][i] = output[0][i][j];
        }
      }
      // print("📊 Transposed detections count: ${transposedOutput.length}");

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
        // print("🔍 Raw bounding box: cx=$cx, cy=$cy, width=$boxWidth, height=$boxHeight");

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
            'x': cx,
            'y': cy,
            'width': boxWidth,
            'height': boxHeight,
            'label': label,
            'confidence': maxScore,
          });
          // print("🎯 Detected: $label with confidence $maxScore");
        }
      }

      // print("<detections> Before NMS: $detections");
      detections = _applyNMS(detections);
      // print("<detections> After NMS: $detections");


    } catch (e) {
      // print("❌ Error running model: $e \n");
    }
    timers['NMS']?.stop();
    print('🕒🕒🕒🕒🕒🕒🕒🕒 '
        'Yolo_service Base: ${timers['base']?.elapsedMilliseconds}ms, '
        'preprocess: ${timers['preprocess']?.elapsedMilliseconds}ms,'
        'interpreter: ${timers['interpreter']?.elapsedMilliseconds}ms,'
        'NMS: ${timers['NMS']?.elapsedMilliseconds}ms'
    );
    timers['base']?.reset();
    timers['preprocess']?.reset();
    timers['interpreter']?.reset();
    timers['NMS']?.reset();
    return detections;

  }

  List<Map<String, dynamic>> _applyNMS(List<Map<String, dynamic>> detections) {
    detections.sort((a, b) => b['confidence'].compareTo(a['confidence']));

    final List<Map<String, dynamic>> filtered = [];
    while (detections.isNotEmpty) {
      final current = detections.removeAt(0);
      filtered.add(current);

      double threshold = 0.5; // make this extremely large to deactivate IoU
      detections.removeWhere((det) => _calculateIoU(current, det) > threshold);
    }
    return filtered;
  }
  //️ fix the boundingbox overlap problem.
  double _calculateIoU(Map<String, dynamic> a, Map<String, dynamic> b) {
    final aLeft = a['x'] - a['width'] / 2;
    final aTop = a['y'] - a['height'] / 2;
    final aRight = aLeft + a['width'];
    final aBottom = aTop + a['height'];

    final bLeft = b['x'] - b['width'] / 2;
    final bTop = b['y'] - b['height'] / 2;
    final bRight = bLeft + b['width'];
    final bBottom = bTop + b['height'];

    final interLeft = max(aLeft, bLeft);
    final interTop = max(aTop, bTop);
    final interRight = min(aRight, bRight);
    final interBottom = min(aBottom, bBottom);

    if (interRight <= interLeft || interBottom <= interTop) return 0.0;

    final intersection = (interRight - interLeft) * (interBottom - interTop);
    final union = a['width']*a['height'] + b['width']*b['height'] - intersection;

    return intersection / union;
  }

}