/// Homepage is the main screen for the app where real-time
/// object detection is performed. It handles camera initialization,
/// image capture, model inference, and switching between different modes.
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:vibration/vibration.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'bounding_box_painter.dart';
import 'yolo_service.dart';
import 'dart:async';

/// Stateful widget representing the homepage with real-time object detection.
class Homepage extends StatefulWidget {
  @override
  _HomepageState createState() => _HomepageState();
}

/// _HomepageState handles everything related to the camera lifecycle, detection loops, and UI updates.
/// It also observes the widget lifecycle to reinitialize the camera if needed.
class _HomepageState extends State<Homepage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  final YoloService _yoloService = YoloService();
  bool _isCameraInitialized = false;
  List<Map<String, dynamic>> _detections = [];
  bool _isDetecting = false;
  bool _isPaused = false; // Pauses detection when switching modes.
  bool _isCaptureActive = false; // Prevents overlapping picture captures.

  // Listing the available modes for the application.
  final List<String> modes = [
    'Object Detection',
    'Object Search',
    'Text Recognition'
  ];
  int currentModeIndex = 0;

  @override
  void initState() {
    super.initState();
    // Register as an observer to listen for app lifecycle changes.
    WidgetsBinding.instance.addObserver(this);
    _checkCameraPermission();
    _yoloService.loadModel();
  }

  @override
  void dispose() {
    // Unregister the lifecycle observer and dispose the camera controller.
    WidgetsBinding.instance.removeObserver(this);
    _disposeCameraController();
    super.dispose();
  }

  /// Disposes the current camera controller if it exists.
  Future<void> _disposeCameraController() async {
    if (_cameraController != null) {
      print("DEBUG: Disposing old camera controller");
      await _cameraController!.dispose();
      _cameraController = null;
    }
  }

  /// Listens to app lifecycle changes to reinitialize the camera when needed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the camera is not initialized, there's nothing to do.
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    if (state == AppLifecycleState.paused) {
      print("DEBUG: App paused, disposing camera controller");
      _disposeCameraController();
    } else if (state == AppLifecycleState.resumed) {
      print("DEBUG: App resumed, reinitializing camera");
      _initCamera();
    }
  }

  /// Checking if the user allowed for camera permissions and initializes the camera if granted.
  Future<void> _checkCameraPermission() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      _initCamera();
    } else {
      print("❌ Camera permission denied");
    }
  }

  /// Most devices have several cameras so I am selecting the first working one
  /// Enforcing the flash of and focus lock, and starting the detection loop.
  Future<void> _initCamera() async {
    // Dispose any existing controller for fresh initialization.
    await _disposeCameraController();
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController =
          CameraController(_cameras![0], ResolutionPreset.high);
      try {
        // Initialize the camera controller.
        await _cameraController!.initialize();
        // Disable flash.
        await _cameraController!.setFlashMode(FlashMode.off);
        // Attempt to lock the focus mode.
        try {
          await _cameraController!.setFocusMode(FocusMode.locked);
        } catch (e) {
          print("Focus lock failed: $e");
        }
        // Update state to reflect successful initialization.
        setState(() {
          _isCameraInitialized = true;
        });
        print("DEBUG: Camera reinitialized in Homepage");
        // Start detection if not paused.
        if (!_isPaused) _startDetectionLoop();
      } catch (e) {
        print("❌ Error initializing camera: $e");
      }
    }
  }

  /// Begins the detection loop by capturing an image, running inference,
  /// and updating the UI with detection results. and then repeat.
  void _startDetectionLoop() async {
    // Ensure camera is ready and detection is not already in progress or paused.
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
      // Capture a picture from the camera.
      final imageFile = await _cameraController!.takePicture();
      print("DEBUG: Capture ended");
      _isCaptureActive = false;
      final bytes = await imageFile.readAsBytes();
      // Decode the captured image using the image package.
      img.Image? capturedImage = img.decodeImage(bytes);
      if (capturedImage != null) {
        // Measure the inference time for debugging.
        Stopwatch modelStopwatch = Stopwatch()..start();
        List<Map<String, dynamic>> results =
        await _yoloService.runModel(capturedImage);
        modelStopwatch.stop();
        print("DEBUG: Model inference took: ${modelStopwatch.elapsedMilliseconds} ms");
        // Update the state with the detection results.
        setState(() {
          _detections = results;
        });
      }
    } catch (e) {
      print("Error in detection loop: $e");
      _isCaptureActive = false;
    } finally {
      _isDetecting = false;
      // Restart the detection loop after a short delay if not paused.
      if (!_isPaused) {
        Future.delayed(Duration(milliseconds: 500), () {
          if (!_isPaused) _startDetectionLoop();
        });
      }
    }
  }

  /// Handles switching between different modes (Object Detection, Object Search,
  /// Text Recognition) and manages camera state accordingly.
  void _switchMode() {
    // Vibrate to provide some sort of feedback for the mode switch.
    // let's settle for this duration to save battery power
    Vibration.vibrate(duration: 100);
    setState(() {
      // Switch through the available modes.
      currentModeIndex = (currentModeIndex + 1) % modes.length;
    });
    print("DEBUG: Switching mode to ${modes[currentModeIndex]}");
    if (modes[currentModeIndex] != 'Object Detection') {
      // Pause the detection loop when leaving object detection mode.
      _isPaused = true;
      print("DEBUG: Detection loop paused in Homepage");
      // If switching to Text Recognition, navigate to the correct page of code.
      if (modes[currentModeIndex] == 'Text Recognition') {
        Navigator.pushNamed(context, '/textModel').then((_) {
          // On returning, resume object detection by reinitializing the camera.
          _isPaused = false;
          print("DEBUG: Resuming detection loop in Homepage");
          _disposeCameraController().then((_) {
            _initCamera();
          });
        });
      }
    } else {
      // When switching back to Object Detection, resume the detection loop.
      _isPaused = false;
      print("DEBUG: Resuming detection loop in Homepage");
      _disposeCameraController().then((_) {
        _initCamera();
      });
    }
  }

  /// Builds the UI for the Homepage. This includes the camera preview,
  /// bounding box overlay, and mode switching controls.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Speak Sight')),
      body: _isCameraInitialized
          ? Stack(
        children: [
          // Display the live camera preview.
          Positioned.fill(child: CameraPreview(_cameraController!)),
          // Overlay detection bounding boxes using a CustomPainter.
          Positioned.fill(
            child: CustomPaint(painter: BoundingBoxPainter(_detections)),
          ),
          // Display current mode and provide touch controls for mode switching.
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
