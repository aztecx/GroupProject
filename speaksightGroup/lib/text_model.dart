import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TextModelPage extends StatefulWidget {
  const TextModelPage({super.key});

  @override
  State<TextModelPage> createState() => _TextModelPageState();
}

class _TextModelPageState extends State<TextModelPage> {
  late TextRecognizer textRecognizer;
  String? selectedImagePath;
  String recognizedText = "";
  bool isRecognizing = false;
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    print("TextModelPage initialized");
  }

  Future<void> _selectImageAndProcess(String assetPath) async {
  setState(() {
    selectedImagePath = assetPath;
    isRecognizing = true;
  });

  try {
    // Copy asset image to a temporary file
    final tempFile = await _copyAssetToFile(assetPath);

    // Modify here to change the image input to real time 
    final inputImage = InputImage.fromFilePath(tempFile.path);
    final RecognizedText recognisedText = await textRecognizer.processImage(inputImage);

    setState(() {
      recognizedText = recognisedText.text;
      print(recognizedText);
      _flutterTts.speak(recognizedText);
    });
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error recognizing text: $e'),
      ),
    );
  } finally {
    setState(() {
      isRecognizing = false;
    });
  }
}

// Function to copy an asset image to a temporary file
Future<File> _copyAssetToFile(String assetPath) async {
  final byteData = await rootBundle.load(assetPath);
  final tempDir = await getTemporaryDirectory();  // Ensure async call
  final tempFile = File('${tempDir.path}/temp_image.png');

  await tempFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
  return tempFile;
}

  void _showImageSelectionModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Select Image 1'),
                onTap: () {
                  Navigator.pop(context);
                  _selectImageAndProcess('assets/images/text.png');
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Select Image 2'),
                onTap: () {
                  Navigator.pop(context);
                  _selectImageAndProcess('assets/images/text.png');
                },
              ),
              // Add more ListTile widgets for additional images
            ],
          ),
        );
      },
    );
  }

  // void _copyTextToClipboard() async {
  //   if (recognizedText.isNotEmpty) {
  //     await Clipboard.setData(ClipboardData(text: recognizedText));
  //     if (!mounted) {
  //       return;
  //     }

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Text copied to clipboard'),
  //       ),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ML Text Recognition'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: selectedImagePath == null
                  ? const Icon(
                      Icons.image,
                      size: 100,
                      color: Colors.grey,
                    )
                  : Image.asset(
                      selectedImagePath!,
                      width: 100,
                      height: 100,
                    ),
            ),
            ElevatedButton(
              onPressed: isRecognizing ? null : _showImageSelectionModal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select an image'),
                  if (isRecognizing) ...[
                    const SizedBox(width: 20),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recognized Text",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // if (!isRecognizing) ...[
            //   Expanded(
            //     child: Scrollbar(
            //       child: SingleChildScrollView(
            //         padding: const EdgeInsets.all(16),
            //         child: Row(
            //           children: [
            //             Flexible(
            //               child: SelectableText(
            //                 recognizedText.isEmpty
            //                     ? "No text recognized"
            //                     : recognizedText,
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ),
            //   ),
            // ],
          ],
        ),
      ),
    );
  }
}