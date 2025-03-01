// lib/homepage.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:vibration/vibration.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'bounding_box_painter.dart';
import 'yolo_service.dart';
import 'dart:async';


class Homepage extends StatefulWidget {
  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  final YoloService _yoloService = YoloService();
  bool _isCameraInitialized = false;
  List<Map<String, dynamic>> _detections = [];

  final List<String> modes = [
    'Object Detection',
    'Object Search',
    'Text Recognition'
  ];
  int currentModeIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
    _yoloService.loadModel();
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
    if (_cameras!.isNotEmpty) {
      _cameraController = CameraController(_cameras![0], ResolutionPreset.medium);
      await _cameraController!.initialize();

      setState(() {
        _isCameraInitialized = true;
      });

      _startDetectionLoop();
    }
  }

  void _startDetectionLoop() {
    Timer.periodic(Duration(seconds: 2), (_) async {
      if (!_cameraController!.value.isInitialized) return;

      final imageFile = await _cameraController!.takePicture();
      final bytes = await imageFile.readAsBytes();
      img.Image? capturedImage = img.decodeImage(bytes);

      if (capturedImage != null) {
        List<Map<String, dynamic>> results = await _yoloService.runModel(capturedImage);
        setState(() {
          _detections = results;
        });
      }
    });
  }

  void _switchMode() {
    Vibration.vibrate(duration: 100);
    setState(() {
      currentModeIndex = (currentModeIndex + 1) % modes.length;
    });

    if (modes[currentModeIndex] == 'Text Recognition') {
      Navigator.pushNamed(context, '/textModel');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Speak Sight')),
      body: _isCameraInitialized
          ? Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: BoundingBoxPainter(_detections),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Current Mode: ${modes[currentModeIndex]}',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
                GestureDetector(
                  onTap: () => Vibration.vibrate(duration: 50),
                  onDoubleTap: _switchMode,
                  child: Icon(Icons.touch_app, size: 50, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      )
          : Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}