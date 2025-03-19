import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'dart:math' as math;


/// YoloService provides object detection functionality for the application.
///
/// This service utilizes a YOLOv11n (You Only Look Once) model to detect objects
/// in camera frames. It handles loading the TensorFlow Lite model, preprocessing
/// images to match the model's input requirements, running inference, and 
/// post-processing detection results with non-maximum suppression to remove
/// duplicate detections.
class YoloService {
  
  final timers = <String, Stopwatch>{
    'base': Stopwatch(),
    'preprocess': Stopwatch(),
    'interpreter': Stopwatch(),
    'NMS': Stopwatch()
  };

  late tfl.Interpreter _interpreter;

  List<String> _labels = [];
  static const _inputSize = 320;
  static const _confidenceThreshold = 0.45;
  static const _nmsThreshold = 0.5;
  static const _gridSize = 50; 

  final bool modelOutputsNormalized = true;

  late int dx;
  late int dy;
  late double scale;

  /// Resizes and pads the input image to match model requirements.
  /// 
  /// The model requires a square input of 320 x 320 pixels.
  /// This method:
  /// 1. Scales the image while preserving aspect ratio
  /// 2. Pads with gray pixels to reach _inputSize in both dimensions
  /// 3. Sets dx, dy and scale for later coordinate conversion
  /// 
  /// Parameters:
  ///   image: The original image to be processed
  /// 
  /// Returns:
  ///   A padded square image of _inputSize x _inputSize pixels
  img.Image _resizedImage(img.Image image) {
    final originalWidth = image.width;
    final originalHeight = image.height;

    // calculating ratio
    scale = min(_inputSize / originalWidth, _inputSize / originalHeight);
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

  /// Normalizes image pixel values for model input.
  /// 
  /// Converts image pixels to a normalized Float32List where values
  /// are scaled from 0-255 to 0-1 range as required by the model.
  /// Uses RGB channel order.
  /// 
  /// Parameters:
  ///   image: The image to normalize
  /// 
  /// Returns:
  ///   Float32List with normalized pixel values
  Float32List _prepareInput(img.Image image) {
    final bytes = image.getBytes(order: img.ChannelOrder.rgb);
    final input = Float32List(_inputSize * _inputSize * 3);
    for (var i = 0; i < bytes.length; i++) {
      input[i] = bytes[i] / 255.0;
    }
    return input;
  }

  /// Loads the YOLO model and class labels from assets.
  /// 
  /// Initializes the TensorFlow Lite interpreter with the model file
  /// and loads object class labels from a text file. Sets up the model
  /// with optimized settings for mobile inference.
  /// 
  /// Throws an exception if model loading fails.
  Future<void> loadModel() async {

    try {
      final options = tfl.InterpreterOptions()
        ..threads = 2;

      // print("🔄 Checking if model file exists...");
      _interpreter = await tfl.Interpreter.fromAsset('assets/models/yolo11n_float16.tflite');
      print("✅ Model file exists!");

      // Load labels from the file.
      String labelsData = await rootBundle.loadString('assets/labels/coco_labels.txt');
      _labels = labelsData.split('\n').where((line) => line.trim().isNotEmpty).toList();
      print("✅ Labels Loaded: ${_labels.length} labels");
      print("✅ Model Loaded Successfully!");


      // var inputTensors = _interpreter.getInputTensors();
      // print("Input tensor type: ${inputTensors[0].type}");
      // print("Input tensor shape: ${inputTensors[0].shape}");

    } catch (e) {
      print("❌ Error loading model: $e");
    }
  }

  /// Performs object detection on an image.
  /// 
  /// This method:
  /// 1. Preprocesses the image (resize, pad, normalize)
  /// 2. Runs the YOLO model inference
  /// 3. Processes the model output to extract detections
  /// 4. Applies non-maximum suppression to filter overlapping boxes
  /// 5. Converts coordinates from model space to original image space
  /// 
  /// Parameters:
  ///   image: The input image for object detection
  /// 
  /// Returns:
  ///   A list of maps, each containing detection information:
  ///   - x, y: Center coordinates of the bounding box (normalized)
  ///   - width, height: Dimensions of the bounding box (normalized)
  ///   - label: Name of the detected object
  ///   - confidence: Detection confidence score
  ///   - denormalizedX, denormalizedY: Center coordinates in original image space
  Future<List<Map<String, dynamic>>> runModel(img.Image image) async {
    List<Map<String, dynamic>> detections = [];
    try {

      timers['base']?.start();
      timers['preprocess']?.start();
      timers['interpreter']?.start();
      timers['NMS']?.start();

      timers['base']?.stop();
      final processedImage = _resizedImage(image);
      final input = _prepareInput(processedImage);
      // print("📊 Image Preprocessing Done!");

      timers['preprocess']?.stop();

      // ⚠️内存溢出问题，很可能是由output这里导致的, 84x2100个double数据。
      List<List<List<double>>> ?output = List<List<List<double>>>.generate(
        1,
            (_) => List<List<double>>.generate(84, (_) => List<double>.filled(2100, 0.0, growable: false),
            growable: false),
      );


      _interpreter.run(input.buffer, output);
      // print("📊 Model output shape: [${output.length}, ${output[0].length}, ${output[0][0].length}]");
      timers['interpreter']?.stop();

      // Transpose output from [1,84,2100] to [1,2100,84]
      List<List<double>> transposedOutput = List.generate(2100, (_) => List.filled(84, 0.0));
      for (int i = 0; i < 84; i++) {
        for (int j = 0; j < 2100; j++) {
          transposedOutput[j][i] = output[0][i][j];
        }
      }

      output = null;
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

        // print("🔍 Raw bounding box: cx=$cx, cy=$cy, width=$boxWidth, height=$boxHeight");
        double denormalizedCx = (cx*_inputSize-dx)/scale;
        double denormalizedCy = (cy*_inputSize-dy)/scale;
        double denormalizedBoxwidth = boxWidth*_inputSize/scale;
        double denormalizedBoxheight = boxHeight*_inputSize/scale;
        // print("1️⃣ Denormalized bounding box: cx=$denormalized_cx, cy=$denormalized_cy, width=$denormalized_boxWidth, height=$denormalized_boxHeight");

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
            'denormalizedX': denormalizedCx,
            'denormalizedY': denormalizedCy,
            // 'denormalizedWidth': denormalizedBoxwidth,
            // 'denormalizedHeight': denormalizedBoxheight,
          });
          // print("🎯 Detected: $label with confidence $maxScore");
        }
      }

      // print("❌<detections> Before NMS: $detections");
      detections = _applyNMS(detections);
      // print("✅<detections> After NMS: $detections");


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

  /// Applies Non-Maximum Suppression to filter overlapping detections.
  /// 
  /// This method:
  /// 1. Sorts detections by confidence (highest first)
  /// 2. Calculates IoU (Intersection over Union) between boxes
  /// 3. Suppresses boxes with high overlap (IoU > threshold) with higher confidence boxes
  /// 
  /// Parameters:
  ///   detections: List of detection results to filter
  /// 
  /// Returns:
  ///   Filtered list of detections with overlapping boxes removed
  List<Map<String, dynamic>> _applyNMS(List<Map<String, dynamic>> detections) {
    // sort detections by confidence
    detections.sort((a, b) => b['confidence'].compareTo(a['confidence']));
    final int n = detections.length;
    final List<bool> suppressed = List.filled(n, false);
    final List<Map<String, dynamic>> result = [];

    // Calculate bounding box coordinates
    final List<double> lefts = List.filled(n, 0.0);
    final List<double> tops = List.filled(n, 0.0);
    final List<double> rights = List.filled(n, 0.0);
    final List<double> bottoms = List.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      final det = detections[i];
      lefts[i] = det['x'] - det['width'] / 2;
      tops[i] = det['y'] - det['height'] / 2;
      rights[i] = lefts[i] + det['width'];
      bottoms[i] = tops[i] + det['height'];
    }

    const double threshold = 0.5;

    // Apply non-maximum suppression
    for (int i = 0; i < n; i++) {
      if (suppressed[i]) continue;
      final current = detections[i];
      result.add(current);

      final double aLeft = lefts[i];
      final double aTop = tops[i];
      final double aRight = rights[i];
      final double aBottom = bottoms[i];
      final double aArea = current['width'] * current['height'];

      // Suppress all detections with IoU > threshold
      for (int j = i + 1; j < n; j++) {
        if (suppressed[j]) continue;
        final double bLeft = lefts[j];
        final double bTop = tops[j];
        final double bRight = rights[j];
        final double bBottom = bottoms[j];
        final double bArea = detections[j]['width'] * detections[j]['height'];

        final double interLeft = math.max(aLeft, bLeft);
        final double interTop = math.max(aTop, bTop);
        final double interRight = math.min(aRight, bRight);
        final double interBottom = math.min(aBottom, bBottom);

        final double interWidth = math.max(0, interRight - interLeft);
        final double interHeight = math.max(0, interBottom - interTop);
        final double intersection = interWidth * interHeight;
        final double union = aArea + bArea - intersection;

        final double iou = (union > 0) ? (intersection / union) : 0.0;
        if (iou > threshold) {
          suppressed[j] = true;
        }
      }
    }
    return result;
  }

}