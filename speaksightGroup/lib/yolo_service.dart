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
  late List<String> labels = [];
  bool _isLabelsLoaded = false;
  final FlutterTts _flutterTts = FlutterTts();
  List<String> _labels = []; // ✅ List to store class labels

  Future<void> _loadLabels() async{
    try{
      final labelsName = await rootBundle.loadString(labelsPath);
      labels = labelsName.split('\n').map((e)=>e.trim()).toList();
      labels.removeWhere((label)=>label.isEmpty);
      _isLabelsLoaded = true;
      print("✅ ${labels.length} labels are loaded");
      if (labels.length != 80) {
        print("⚠️ Warning: Expected 80 labels, got ${labels.length}");
      }
    }catch(e){
      print("❌ Error loading labels: $e");
      labels=[];
    }
  }

  Future<void> loadModel() async {
    try {
      await _loadLabels();
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

  Future<void> _loadLabels() async {
    try {
      String labelsString = await rootBundle.loadString(labelsPath);
      _labels = labelsString.split('\n').map((label) => label.trim()).toList();
      print("✅ Labels Loaded Successfully! (${_labels.length} labels)");
    } catch (e) {
      print("❌ Error loading labels: $e");
    }
  }

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

    Float32List floatData = Float32List(1 * inputSize * inputSize * 3); // ✅ Ensure correct input shape
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

    print("📊 Image Preprocessing Done (Corrected for YOLOv8)!");
    return floatData; // ✅ Return Float32List directly
  }

  String getLabels(int classID){
    if(!_isLabelsLoaded) return "Labels are not loaded";
    if(classID<0 || classID>=labels.length) return "classID out of range";
    return labels[classID];
  }

  /// ✅ **Process YOLOv8 Output Correctly**
  List<Map<String, dynamic>> processOutput(List<List<List<double>>> output, int inputSize) {
    List<Map<String, dynamic>> detections = [];

    for (int i = 0; i < output[0][0].length; i++) {
      double confidence = output[0][4][i];

      // 🔥 Debugging: Print Raw Outputs
      // print("RAW OUTPUT [i=$i]\n x=${output[0][0][i]}, y=${output[0][1][i]}\n width=${output[0][2][i]}, height=${output[0][3][i]}\n confidence=${confidence}");
      print("RAW OUTPUT [i=$i]: x=${output[0][0][i]}, y=${output[0][1][i]}, width=${output[0][2][i]}, height=${output[0][3][i]}, confidence=$confidence");
      print(output[0][5][i] * 100000000);


      if (confidence > 0.2) { // ✅ Lowered for debugging
        int classId = 0;
        double maxClassProb = 0.0;

        for (int j = 5; j < 85; j++) {
          if (output[0][j][i] > maxClassProb) {
            maxClassProb = output[0][j][i];
            classId = j - 5;
          }
        }


        // String label = getLabels(classId);

        // ✅ Get label from loaded labels list
        String label = (classId >= 0 && classId < _labels.length)
            ? _labels[classId]
            : "Unknown";

        print("🎯 Detected: $label with confidence ${(confidence * 100).toInt()}%");
        _flutterTts.speak("Detected $label");

        detections.add({
          "label": label,
          "confidence": confidence,
          "x": output[0][0][i] ,
          "y": output[0][1][i] ,
          "width": output[0][2][i] ,
          "height": output[0][3][i] ,
        });
      }
    }

    if (detections.isEmpty) {
      print("🚨 No objects detected.");
    }

    return detections;
  }
}
