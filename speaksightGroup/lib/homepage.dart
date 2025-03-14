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

class _HomepageState extends State<Homepage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  final YoloService _yoloService = YoloService();
  bool _isCameraInitialized = false;
  List<Map<String, dynamic>> _detections = [];
  bool _isDetecting = false;
  bool _isPaused = false; // Pause detection when switching modes
  bool _isCaptureActive = false; // Prevent overlapping picture captures

  final List<String> modes = [
    'Object Detection',
    'Object Search',
    'Text Recognition'
  ];
  int currentModeIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkCameraPermission();
    _yoloService.loadModel();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCameraController();
    super.dispose();
  }

  Future<void> _disposeCameraController() async {
    if (_cameraController != null) {
      print("DEBUG: Disposing old camera controller");
      await _cameraController!.dispose();
      _cameraController = null;
    }
  }

  // Lifecycle observer: reinitialize camera on resume.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (state == AppLifecycleState.paused) {
      print("DEBUG: App paused, disposing camera controller");
      _disposeCameraController();
    } else if (state == AppLifecycleState.resumed) {
      print("DEBUG: App resumed, reinitializing camera");
      _initCamera();
    }
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
    // Dispose any existing controller to ensure fresh reinitialization.
    await _disposeCameraController();
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController =
          CameraController(_cameras![0], ResolutionPreset.high);
      try {
        await _cameraController!.initialize();
        // Disable flash and lock focus.
        await _cameraController!.setFlashMode(FlashMode.off);
        try {
          await _cameraController!.setFocusMode(FocusMode.locked);
        } catch (e) {
          print("Focus lock failed: $e");
        }
        setState(() {
          _isCameraInitialized = true;
        });
        print("DEBUG: Camera reinitialized in Homepage");
        if (!_isPaused) _startDetectionLoop();
      } catch (e) {
        print("❌ Error initializing camera: $e");
      }
    }
  }

  void _startDetectionLoop() async {
    if (!_isCameraInitialized || _isDetecting || _isPaused) return;
    if (_isCaptureActive) {
      print("DEBUG: Capture already active, skipping this loop");
      return;
    }
    print("DEBUG: Starting detection loop in Homepage");
    _isDetecting = true;
    _isCaptureActive = true;

    try {
      print("DEBUG: Capture started");
      final imageFile = await _cameraController!.takePicture();
      print("DEBUG: Capture ended");
      _isCaptureActive = false;
      final bytes = await imageFile.readAsBytes();
      img.Image? capturedImage = img.decodeImage(bytes);
      if (capturedImage != null) {
        Stopwatch modelStopwatch = Stopwatch()..start();
        List<Map<String, dynamic>> results =
        await _yoloService.runModel(capturedImage);
        modelStopwatch.stop();
        print("DEBUG: Model inference took: ${modelStopwatch.elapsedMilliseconds} ms");
        setState(() {
          _detections = results;
        });
      }
    } catch (e) {
      print("Error in detection loop: $e");
      _isCaptureActive = false;
    } finally {
      _isDetecting = false;
      if (!_isPaused) {
        Future.delayed(Duration(milliseconds: 500), () {
          if (!_isPaused) _startDetectionLoop();
        });
      }
    }
  }

  void _switchMode() {
    Vibration.vibrate(duration: 100);
    setState(() {
      currentModeIndex = (currentModeIndex + 1) % modes.length;
    });
    print("DEBUG: Switching mode to ${modes[currentModeIndex]}");
    if (modes[currentModeIndex] != 'Object Detection') {
      // Pause the object detection loop.
      _isPaused = true;
      print("DEBUG: Detection loop paused in Homepage");
      // If switching to Text Recognition, navigate to that page.
      if (modes[currentModeIndex] == 'Text Recognition') {
        Navigator.pushNamed(context, '/textModel').then((_) {
          // On return, force reinitialize the camera.
          _isPaused = false;
          print("DEBUG: Resuming detection loop in Homepage");
          _disposeCameraController().then((_) {
            _initCamera();
          });
        });
      }
      // (Handle 'Object Search' similarly if needed.)
    } else {
      // If switching back to Object Detection, force reinitialize the camera.
      _isPaused = false;
      print("DEBUG: Resuming detection loop in Homepage");
      _disposeCameraController().then((_) {
        _initCamera();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Speak Sight')),
      body: _isCameraInitialized
          ? Stack(
        children: [
          Positioned.fill(child: CameraPreview(_cameraController!)),
          Positioned.fill(
            child: CustomPaint(painter: BoundingBoxPainter(_detections)),
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
          : Center(child: CircularProgressIndicator()),
    );
  }
}
