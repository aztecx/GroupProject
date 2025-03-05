import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image/image.dart' as img;

// Text Service class where the text recognition model is loaded and the image is processed
class TextService {
  late TextRecognizer textRecognizer;
  String? selectedImagePath;
  String recognisedText = "";
  final FlutterTts _flutterTts = FlutterTts();
  String assetPath = 'assets/images/text.png';

  // Load the text recognition model
  Future loadModel() async {
    // Initialize the Text Recognizer
    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    print("✅Text Model loaded");
  }

  // Copy the asset image to a temporary file
  Future<File> _copyAssetToFile(String assetPath) async {
    String tempDirectoryPath = (await getTemporaryDirectory()).path; // Get the temporary directory path
    final file = File('$tempDirectoryPath/$assetPath'); // Create a temporary file to store the image

    final byteData = await rootBundle.load(assetPath); // Load the image from the asset path
    
    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true); // Write the image to the temporary file

    return file;
  }

  // Process the image and recognize the text
  Future<String> runModel(img.Image image) async {
    try {
      // Copy asset image to a temporary file
      final tempFile = await _copyAssetToFile(assetPath);

      // Modify here to change the image input to real time 
      final inputImage = InputImage.fromFilePath(tempFile.path);
      final RecognizedText textResult = await textRecognizer.processImage(inputImage); 

        recognisedText = textResult.text;
        print(recognisedText);
        _flutterTts.speak(recognisedText);
    } catch (e) {
      // if (!mounted) return;
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Error recognizing text: $e'),
      //   ),
      // );
      print("❌ Error loading text model: $e");
    }
    return recognisedText;
  }
}