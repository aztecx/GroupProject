// lib/text_model.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'text_service.dart';
import 'dart:async';

class TextModelPage extends StatefulWidget {
  @override
  _TextModelPageState createState() => _TextModelPageState();
}

class _TextModelPageState extends State<TextModelPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  final TextService _textService = TextService();
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  String _recognizedText = "";
  bool _isActive = true;
  bool _isCaptureActive = false; // Prevent overlapping captures
  int _frameSkipCounter = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _textService.loadModel();
    await _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      _initCamera();
    } else {
      print("❌ Camera permission denied");
    }
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController =
          CameraController(_cameras![0], ResolutionPreset.medium);
      try {
        await _cameraController!.initialize();
        if (!_isActive) return;
        setState(() {
          _isCameraInitialized = true;
        });
        print("DEBUG: Camera initialized in TextModelPage");
        _startDetectionLoop();
      } catch (e) {
        print("❌ Error initializing camera in TextModelPage: $e");
      }
    }
  }

  void _startDetectionLoop() async {
    if (!_isActive ||
        !_cameraController!.value.isInitialized ||
        _isDetecting) return;

    // Frame skipping: process every third frame.
    if (_frameSkipCounter < 2) {
      _frameSkipCounter++;
      Future.delayed(Duration(milliseconds: 500), () => _startDetectionLoop());
      return;
    } else {
      _frameSkipCounter = 0;
    }

    if (_isCaptureActive) return;
    _isDetecting = true;
    _isCaptureActive = true;

    try {
      print("DEBUG: TextModelPage capture started");
      final imageFile = await _cameraController!.takePicture();
      print("DEBUG: TextModelPage capture ended");
      _isCaptureActive = false;
      await _textService.runModel(imageFile.path);
      setState(() {
        _recognizedText = _textService.recognizedText;
      });
    } catch (e) {
      print("❌ Error in text detection loop: $e");
      _isCaptureActive = false;
    } finally {
      _isDetecting = false;
      if (!_isActive) return;
      Future.delayed(Duration(milliseconds: 500), () {
        if (!_isActive) return;
        _startDetectionLoop();
      });
    }
  }

  @override
  void dispose() {
    _isActive = false;
    _textService.stopSpeech();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Live Text Recognition"),
      ),
      body: GestureDetector(
        onDoubleTap: () {
          Navigator.pop(context);
        },
        child: _isCameraInitialized
            ? Stack(
          children: [
            Positioned.fill(child: CameraPreview(_cameraController!)),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(12),
                color: Colors.black54,
                child: SingleChildScrollView(
                  child: Text(
                    _recognizedText,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        )
            : Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
