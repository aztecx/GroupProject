// lib/text_service.dart
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TextService {
  late TextRecognizer textRecognizer;
  String recognizedText = "";
  String lastSpokenText = "";
  // Set an initial cooldown so that TTS doesn’t fire too frequently.
  DateTime _lastSpokenTime = DateTime.now().subtract(Duration(seconds: 10));
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> loadModel() async {
    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    print("DEBUG: Text Model loaded");
  }

  // Normalize text to lower case and remove extra whitespace.
  String normalizeText(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<void> runModel(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognized = await textRecognizer.processImage(inputImage);
      recognizedText = normalizeText(recognized.text);
      print("DEBUG: Recognized Text: $recognizedText");

      // Only speak if the text is non-empty, different from last spoken,
      // and at least 5 seconds have passed.
      if (recognizedText.isNotEmpty &&
          recognizedText != lastSpokenText &&
          DateTime.now().difference(_lastSpokenTime) > Duration(seconds: 5)) {
        lastSpokenText = recognizedText;
        _lastSpokenTime = DateTime.now();
        print("DEBUG: TTS triggered: $recognizedText");
        await _flutterTts.speak(recognizedText);
      }
    } catch (e) {
      print("❌ Error running text model: $e");
    }
  }

  Future<void> stopSpeech() async {
    print("DEBUG: Stopping TTS");
    await _flutterTts.stop();
  }
}
