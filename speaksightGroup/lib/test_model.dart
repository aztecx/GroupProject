// lib/test_text.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'text_service.dart';

class TestTextPage extends StatefulWidget {
  @override
  _TestTextPageState createState() => _TestTextPageState();
}

class _TestTextPageState extends State<TestTextPage> {
  final TextService _textService = TextService();
  String _recognizedText = "";
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    // Load the text recognition model once.
    _textService.loadModel();
  }

  // Function to pick an image from camera or gallery.
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _recognizedText = "Processing...";
      });
      // Process the image using the text recognition model.
      await _textService.runModel(pickedFile.path);
      setState(() {
        _recognizedText = _textService.recognizedText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Test Text Recognition"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Display the image if one has been selected.
            if (_imageFile != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.file(_imageFile!),
              ),
            SizedBox(height: 20),
            // Display recognized text.
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _recognizedText,
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            // Button to capture an image using the camera.
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.camera),
              child: Text("Capture Image"),
            ),
            SizedBox(height: 10),
            // Button to upload an image from the gallery.
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery),
              child: Text("Upload Image"),
            ),
          ],
        ),
      ),
    );
  }
}
