import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

// Text Service class where the text recognition model is loaded and the image is processed
class TextService {
  late TextRecognizer textRecognizer;
  String? selectedImagePath;


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
    String recognisedText = '';
    try {
// Copy asset image to a temporary file
      // final tempFile = await _copyAssetToFile(assetPath);
      // final inputImage = InputImage.fromFilePath(tempFile.path);

      // Copy asset image to a temporary file
      // final tempFile = await _copyAssetToFile(assetPath);
      // final inputImage = InputImage.fromFilePath(tempFile.path);

      // Encode your img.Image to JPEG (or PNG)
      final Uint8List encodedBytes = Uint8List.fromList(img.encodeJpg(image));

      // Get a temporary directory
      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/temp.jpg';

      // Write the encoded bytes to a temporary file
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(encodedBytes, flush: true);

      // Create an InputImage from the file path
      final inputImage = InputImage.fromFilePath(tempFilePath);

      final RecognizedText textResult = await textRecognizer.processImage(inputImage); 
      double offest = textResult.blocks.first.boundingBox.center.dy;
      // print(offest);
      recognisedText = textResult.blocks.first.text;
      // print(recognisedText);

    } catch (e) {
// if (!mounted) return;
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Error recognizing text: $e'),
      //   ),
      // );
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

  void dispose() {
    textRecognizer.close();
  }
}