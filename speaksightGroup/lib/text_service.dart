import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

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

  /// Processes an image and recognizes text content within it.
  /// 
  /// This method:
  /// 1. Encodes the provided image to JPEG format
  /// 2. Writes it to a temporary file
  /// 3. Creates an InputImage from the file path
  /// 4. Processes the image with ML Kit's text recognizer
  /// 5. Returns the extracted text as a string
  /// 
  /// Parameters:
  ///   image: The image object to process for text recognition
  /// 
  /// Returns:
  ///   A string containing all recognized text from the image,
  ///   or an empty string if no text was found or an error occurred
  Future<String> runModel(img.Image image) async {
    String recognisedText = '';
    try {
      // Copy asset image to a temporary file
      // final tempFile = await _copyAssetToFile(assetPath);
      // final inputImage = InputImage.fromFilePath(tempFile.path);

      // Encode your img.Image to JPEG
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
      // double offest = textResult;
      // print(offest);
      recognisedText = textResult.text;
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