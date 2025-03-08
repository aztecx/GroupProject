// lib/homepage.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:speaksightgroup/text_service.dart';
import 'package:vibration/vibration.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'bounding_box_painter.dart';
import 'yolo_service.dart';
import 'dart:async';
import 'dart:typed_data';
import 'tts_service.dart';
import 'dart:io';



class Homepage extends StatefulWidget {
  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final timers = <String, Stopwatch>{
    'base': Stopwatch(),
    'runModel': Stopwatch(),
  };
  ttsService tts = ttsService();
  // final FlutterTts _flutterTts = FlutterTts();

  bool isAndroid = Platform.isAndroid;
  bool isIOS = Platform.isIOS;

  // Initialize the camera controller
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  StreamSubscription<CameraImage>? _imageStreamSubscription;

  // Initialize the YOLO service and Text service
  final YoloService _yoloService = YoloService();
  final TextService _textService = TextService();
  
  List<Map<String, dynamic>> _detectedObjects = [];
  String _recognizedText = '';

  bool _isProcessing=false; // ⚠️防止并发处理
  
  // List of modes
  final List<String> modes = [
    'Object Detection',
    // 'Object Search',
    'Text Recognition'
  ];
  int currentModeIndex = 0;


  // Check the camera permission and initialize the camera
  @override
  void initState() {
    super.initState();
    // tts.initTts();
    _checkCameraPermission();
    tts.initTts();

    // Load the YOLO and Text models
    _yoloService.loadModel();
    _textService.loadModel();
    timers['base']?.start();
  }

  // Check the camera permission
  Future<void> _checkCameraPermission() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      _initCamera();
    } else {
      print("❌ Camera permission denied");
    }
  }

  // Initialize the camera
  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    // Initialize the camera controller
    if (_cameras!.isNotEmpty) {
      // use the first camera with medium resolution
      _cameraController = CameraController(_cameras![0], ResolutionPreset.high);
      await _cameraController!.initialize();

      setState(() {
        _isCameraInitialized = true;
      });

      // Start the detection loop
      _startDetectionLoop();
    }
  }

  void _startDetectionLoop() async {
    // check if the camera is initialized
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    // ⚠️changed: takePicture --> startImageStream
    // Start the image stream
    await _cameraController!.startImageStream((CameraImage image) async {
      if (_isProcessing) return;
      _isProcessing = true;

      try {
        // Turn <CameraImage> into <img.Image>
        final img.Image? convertedImage = await _convertCameraImage(image);

        timers['runModel']?.start();

        // Run the YOLO model
        if (convertedImage != null) {
          if (modes[currentModeIndex] == 'Object Detection') {
            final results = await _yoloService.runModel(convertedImage);
            setState(() => _detectedObjects = results);
            tts.speakObject(_detectedObjects);

          } else if (modes[currentModeIndex] == 'Text Recognition') {
            final results = await _textService.runModel(convertedImage);
            setState(() => _recognizedText = results);
            tts.speakText(_recognizedText);
          }
        }
        timers['runModel']?.stop();
        timers['base']?.stop();
        print('🕒🕒🕒🕒🕒🕒🕒🕒 Base: ${timers['base']?.elapsedMilliseconds}ms, Run Model: ${timers['runModel']?.elapsedMilliseconds}ms');
        timers['runModel']?.reset();
        timers['base']?.start();

      } catch (e) {
        print("❌ Image processing error: $e");
      } finally {
        _isProcessing = false;
      }
    });
  }

  Future<img.Image?> _convertCameraImage(CameraImage image) async {
    try {
      // final int width = image.width;
      // final int height = image.height;

      if (isAndroid) {
        return _convertYUV420ToImage(image);
      } else if (isIOS) {
        return _convertBGRA8888ToImage(image);
      }
      return null;
    } catch (e) {
      print("❌ Image conversion error: $e");
      return null;
    }
  }

  // ⚠️For Camera on Android OS
  img.Image _convertYUV420ToImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;

    final img.Image converted = img.Image(width: width, height: height);

    // YUV to RGB
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex = uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int yIndex = y * width + x;

        final yValue = image.planes[0].bytes[yIndex];
        final uValue = image.planes[1].bytes[uvIndex];
        final vValue = image.planes[2].bytes[uvIndex];

        final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255);
        final g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).clamp(0, 255);
        final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255);

        converted.setPixelRgba(x, y, r.toInt(), g.toInt(), b.toInt(),255);
      }
    }
    return converted;
  }

  // For Camera on iOS
  img.Image _convertBGRA8888ToImage(CameraImage image) {
    final bytes = Uint8List.fromList(image.planes[0].bytes);
    return img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  void _switchMode () async{
    Vibration.vibrate(duration: 100);
    // Switch mode
    // tts = ttsService();
    tts.switchMode();


    setState(() {
      currentModeIndex = (currentModeIndex + 1) % modes.length;
      _detectedObjects.clear();
      print("✅mode is switched");
    });
    tts.speakText('Switch to ${modes[currentModeIndex]}');
    // TODO: stop detecting-->announce the current mode-->continue detecting
    print("⚠️⚠️_detectedObjects is clear: $_detectedObjects");

  }

  @override
  void dispose() {
    _imageStreamSubscription?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Speak Sight')),
      body: _isCameraInitialized
          ? GestureDetector(
              onDoubleTap: _switchMode,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CameraPreview(_cameraController!),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: BoundingBoxPainter(_detectedObjects),
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
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 4)
                            ],
                          ),
                        ),
                        // You can still keep an icon if you want a visual cue.
                        Icon(Icons.touch_app, size: 50, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Center(child: CircularProgressIndicator()),
    );
}


  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(title: Text('Speak Sight')),
  //     body: _isCameraInitialized
  //         ? Stack(
  //           children: [
  //             Positioned.fill(
  //               child: CameraPreview(_cameraController!),
  //               ),
  //               Positioned.fill(
  //                 child: CustomPaint(
  //                   painter: BoundingBoxPainter(_detectedObjects),
  //                   ),
  //                 ),
  //               Positioned(
  //                 bottom: 30,
  //                 left: 0,
  //                 right: 0,
  //                 child: Column(
  //                   children: [
  //                     Text(
  //                 'Current Mode: ${modes[currentModeIndex]}',
  //                 style: TextStyle(
  //                   fontSize: 22,
  //                   color: Colors.white,
  //                   shadows: [Shadow(color: Colors.black, blurRadius: 4)],
  //                 ),
  //               ),
  //               GestureDetector(
  //                 onTap: () => Vibration.vibrate(duration: 50),
  //                 onDoubleTap: _switchMode,
  //                 child: Icon(Icons.touch_app, size: 50, color: Colors.white),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //         )
  //         : Center(
  //       child: CircularProgressIndicator(),
  //     ),
  //   );
  // }
}