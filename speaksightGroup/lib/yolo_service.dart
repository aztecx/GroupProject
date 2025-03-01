import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;
import 'package:flutter_tts/flutter_tts.dart';

class YoloService {
  static const String modelPath = 'assets/models/yolov8n_float16.tflite';
  static const String labelsPath = 'assets/labels/coco_labels.txt';

  late tfl.Interpreter _interpreter;
  bool _isModelLoaded = false;
  final FlutterTts _flutterTts = FlutterTts();
  List<String> _labels = []; // ✅ Stores class labels

  /// ✅ **Loads Labels from File**
  Future<void> _loadLabels() async {
    final rawLabels = await rootBundle.loadString(labelsPath);
    _labels = rawLabels.split('\n').map((label) => label.trim()).toList();
    print("✅ Labels Loaded: ${_labels.length} labels");
  }
  /// ✅ **Loads YOLO Model**
  Future<void> loadModel() async {
    try {
      print("🔄 Checking if model file exists...");
      await rootBundle.load(modelPath);
      print("✅ Model file exists!");

      _interpreter = await tfl.Interpreter.fromAsset(modelPath,
          options: tfl.InterpreterOptions()..threads = 2);
      _isModelLoaded = true;
      print("✅ Model Loaded Successfully!");

      // ✅ Load class labels
      await _loadLabels();
    } catch (e) {
      print("❌ Error loading model: $e");
    }
  }

  /// ✅ **Runs YOLO Model on Image**
  Future<List<Map<String, dynamic>>> runModel(img.Image image) async {
    if (!_isModelLoaded) {
      print('❌ Model not loaded');
      return [];
    }

    int inputSize = 640;
    var input = preprocessImage(image, inputSize);

    // ✅ Ensure correct output structure
    var output = List.generate(1, (_) => List.generate(84, (_) => List.filled(8400, 0.0)));

    try {
      _interpreter.run(input.reshape([1, 640, 640, 3]), output);
    } catch (e) {
      print("❌ Error running model: $e");
      return [];
    }

    return processOutput(output, inputSize);
  }

  /// ✅ **Preprocess Image to Float32 for YOLOv8**
  Float32List preprocessImage(img.Image image, int inputSize) {
    img.Image resized = img.copyResize(image, width: inputSize, height: inputSize);

    Float32List floatData = Float32List(1 * inputSize * inputSize * 3);
    int pixelIndex = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        img.Pixel pixel = resized.getPixel(x, y);

        // ✅ Normalize pixels to range [0, 1]
        floatData[pixelIndex++] = pixel.r / 255.0;
        floatData[pixelIndex++] = pixel.g / 255.0;
        floatData[pixelIndex++] = pixel.b / 255.0;
      }
    }

    print("📊 Image Preprocessing Done!");
    return floatData;
  }

  /// ✅ **Returns Label from Class ID**
  String getLabel(int classID) {
    // if (!_isLabelsLoaded) return "Labels not loaded";
    if (classID < 0 || classID >= _labels.length) return "Unknown";
    return _labels[classID];
  }

  /// ✅ **Processes YOLO Output**
  List<Map<String, dynamic>> processOutput(List<List<List<double>>> output, int inputSize) {
    List<Map<String, dynamic>> detections = [];

    for (int i = 0; i < output[0][0].length; i++) {
      double confidence = output[0][4][i];

      // 🔥 Debugging: Print Raw Outputs
      print("RAW OUTPUT [i=$i]: x=${output[0][0][i]}, y=${output[0][1][i]}, "
          "width=${output[0][2][i]}, height=${output[0][3][i]}, confidence=$confidence");

      if (confidence > 0.75) { // ✅ Lowered for debugging
        int classId = 0;
        double maxClassProb = 0.0;

        print("🔎 Detection [$i]: Confidence=$confidence");

// ✅ Print all class probabilities
        for (int j = 5; j < 84; j++) {
          double classProb = output[0][j][i];

          // 🔥 Debug: Print probability for each class
          print("📊 Class ${j - 5}: ${_labels[j - 5]} | class_Confidence: $classProb");

          if (classProb > maxClassProb) {
            maxClassProb = classProb;
            classId = j - 5;
          }
        }


        // for (int j = 5; j < 84; j++) {
        //   if (output[0][j][i] > maxClassProb) {
        //     maxClassProb = output[0][j][i];
        //     classId = j - 5;
        //   }
        // }

        // ✅ Get label from loaded labels list
        String label = getLabel(classId);

        print("🎯 Detected: $label with confidence $confidence");
        _flutterTts.speak("Detected $label");

        detections.add({
          "label": label,
          "confidence": confidence,
          "x": output[0][0][i],
          "y": output[0][1][i],
          "width": output[0][2][i],
          "height": output[0][3][i],
        });
      }
    }

    if (detections.isEmpty) {
      print("🚨 No objects detected.");
    }

    return detections;
  }
}
