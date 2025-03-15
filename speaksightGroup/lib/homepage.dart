// lib/homepage.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:speaksightgroup/text_service.dart';
import 'package:speaksightgroup/tts_service.dart';
import 'package:speaksightgroup/stt_service.dart';
import 'package:vibration/vibration.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'bounding_box_painter.dart';
import 'yolo_service.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:io';



class Homepage extends StatefulWidget {
  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final timers = <String, Stopwatch>{
    'base': Stopwatch(),
    'runModel': Stopwatch(),
    'lastSpeak':Stopwatch()..start(),

  };

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
  final TtsService _tts = TtsService();
  final SttService _stt = SttService();
  
  // Initialize the result of detected objects and recognized text
  List<Map<String, dynamic>> _detectedObjects = [];
  List<List<String>> _recentDetections = []; // last n frames
  String _recognizedText = '';
  String _finalText = '';
  String _searchTarget = '';

  bool _isProcessing=false; // ⚠️防止并发处理
  bool _isListening = false;
  
  // List of modes
  final List<String>  modes = [
    'Object Detection',
    'Object Search',
    'Text Recognition'
  ];
  int currentModeIndex = 0;

  // Check the camera permission and initialize the camera
  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
    _tts.initTts();
    _stt.init();

    // Load the YOLO model and Text model
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
      _cameraController = CameraController(_cameras![0], ResolutionPreset.medium);
      await _cameraController!.initialize();

      setState(() {
        _isCameraInitialized = true;
      });

      // Start the detection loop
      _startDetectionLoop();
    }
  }

  int _frameCount = 0;
  final int _frameLimit = 15; // ⚠️frame rate control

  void _startDetectionLoop() async {
    // check if the camera is initialized
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    // Start the image stream
    await _cameraController!.startImageStream((CameraImage image) async {
      if(_isListening){
        return;
      }

      _frameCount = (_frameCount + 1) % _frameLimit;
      if (_frameCount % _frameLimit != 0) {
        return;
      }

      if (_isProcessing) return;
      _isProcessing = true;

      try {
        // Turn <CameraImage> into <img.Image>
        final img.Image? convertedImage = await _convertCameraImage(image);

        timers['runModel']?.start();

        // Run the YOLO model
        if (convertedImage != null) {
          if (modes[currentModeIndex] == 'Object Detection') {
            final thisResults = await _yoloService.runModel(convertedImage);
            _tts.setSpeed(0.5);

            setState(() => _detectedObjects = thisResults);
            if(thisResults.isNotEmpty){
              final objectsInThisFrame = thisResults.map((obj) => obj['label'] as String).toList();
              _recentDetections.add(objectsInThisFrame);
              if(_recentDetections.length > 10){ //最近10帧
                _recentDetections.removeAt(0);
              }

              final topFrequencyObj = _getTopFrequency(_recentDetections);
              if(timers['lastSpeak']!=null) {
                int currentTime = timers['lastSpeak']!.elapsedMilliseconds;
                print("Since lastSpeak: $currentTime");
                if (topFrequencyObj != null &&
                     currentTime >= 2000) {
                      _tts.speakText(topFrequencyObj);
                      // print("Since lastSpeak: $currentTime");
                      timers['lastSpeak']?.reset();
                      
                }
              }
            }

          } else if (modes[currentModeIndex] == 'Text Recognition') {
            final results = await _textService.runModel(convertedImage);
            _tts.setSpeed(0.52);
            setState(() => _recognizedText = results);
            // int currentTime = timers['lastSpeak']!.elapsedMilliseconds;
            // if (results.isNotEmpty && currentTime >= 3000) {
            _tts.speakText(_recognizedText);
              // timers['lastSpeak']?.reset();
            // }
          } else if (modes[currentModeIndex] == 'Object Search') {
            final thisResults = await _yoloService.runModel(convertedImage);
            _tts.setSpeed(0.52);
            setState(() => _detectedObjects = thisResults);
            final found = thisResults.where((obj) {
              final label = (obj['label'] as String).toLowerCase();
              return label == _searchTarget.toLowerCase();
              }).toList();

            if (found.isNotEmpty) {
              final targetObj = found.first;

              final double xCenter = targetObj['x'];
              final double yCenter = targetObj['y'];

              final screenWidth = MediaQuery.of(context).size.width;
              final screenHeight = MediaQuery.of(context).size.height;

              final double halfW = screenWidth / 2;
              final double halfH = screenHeight / 2;
              String quadrant;
              if (xCenter < halfW && yCenter < halfH) {
                quadrant = "top-left";
              } else if (xCenter >= halfW && yCenter < halfH) {
                quadrant = "top-right";
              } else if (xCenter < halfW && yCenter >= halfH) {
                quadrant = "bottom-left";
              } else {
                quadrant = "bottom-right";
              }
              print("🎯 Found $_searchTarget at $quadrant");

              _tts.speakText("$_searchTarget at $quadrant");
            }

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
        if (image.format.raw == 17 && image.planes.length == 2) {
          // 说明是 NV21
          print("⚠️NV21");
          return _convertNV21ToImage(image);
        } else {
          print("⚠️YUV420");
          return _convertYUV420ToImage(image);
        }

      } else if (isIOS) {
        print("⚠️iOS Camera Image");
        return _convertBGRA8888ToImage(image);
        // return null;
      }
      return null;
    } catch (e) {
      print("❌ Image conversion error: $e");
      return null;
    }
  }

  img.Image? convertedImage;


  /*
   * For Android Camera
   * Adapted from: https://gist.github.com/Alby-o/fe87e35bc21d534c8220aed7df028e03
   * Author: @ Alby-o
   */
  img.Image _convertYUV420ToImage(CameraImage cameraImage) {
    final imageWidth = cameraImage.width;
    final imageHeight = cameraImage.height;

    if (convertedImage == null ||
        convertedImage!.width != imageWidth ||
        convertedImage!.height != imageHeight) {
      convertedImage = img.Image(width: imageWidth, height: imageHeight);
    }

    final yBuffer = cameraImage.planes[0].bytes;
    final uBuffer = cameraImage.planes[1].bytes;
    final vBuffer = cameraImage.planes[2].bytes;

    final int yRowStride = cameraImage.planes[0].bytesPerRow;
    final int yPixelStride = cameraImage.planes[0].bytesPerPixel!;

    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

    final image = img.Image(width: imageWidth, height: imageHeight);

    for (int h = 0; h < imageHeight; h++) {
      int uvh = (h / 2).floor();

      for (int w = 0; w < imageWidth; w++) {
        int uvw = (w / 2).floor();

        final yIndex = (h * yRowStride) + (w * yPixelStride);

        // Y plane should have positive values belonging to [0...255]
        final int y = yBuffer[yIndex];

        // U/V Values are subsampled i.e. each pixel in U/V chanel in a
        // YUV_420 image act as chroma value for 4 neighbouring pixels
        final int uvIndex = (uvh * uvRowStride) + (uvw * uvPixelStride);

        // U/V values ideally fall under [-0.5, 0.5] range. To fit them into
        // [0, 255] range they are scaled up and centered to 128.
        // Operation below brings U/V values to [-128, 127].
        final int u = uBuffer[uvIndex];
        final int v = vBuffer[uvIndex];

        // Compute RGB values per formula above.
        int r = (y + v * 1436 / 1024 - 179).round();
        int g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91).round();
        int b = (y + u * 1814 / 1024 - 227).round();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        convertedImage!.setPixelRgb(w, h, r, g, b);
      }
    }
    return convertedImage!;
  }

  /*
  * Another kind of Android Camera
  * AI generated
  */
  img.Image? _convertNV21ToImage(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final planeY = image.planes[0];
    final planeVU = image.planes[1];

    final yBytes = planeY.bytes;
    final vuBytes = planeVU.bytes;

    final neededLength = width * height * 4;
    Uint8List rgbaBuffer = Uint8List(neededLength);

    int index = 0;
    for (int y = 0; y < height; y++) {
      final yRowStart = y * planeY.bytesPerRow;
      final uvRowStart = (y >> 1) * planeVU.bytesPerRow;

      for (int x = 0; x < width; x++) {
        // 取 Y
        final yValue = yBytes[yRowStart + x];

        final uvIndex = uvRowStart + (x >> 1) * 2;
        final vValue = vuBytes[uvIndex + 0];
        final uValue = vuBytes[uvIndex + 1];

        final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
        final g = (yValue - 0.344136 * (uValue - 128)
            - 0.714136 * (vValue - 128)).clamp(0, 255).toInt();
        final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

        rgbaBuffer[index++] = r;
        rgbaBuffer[index++] = g;
        rgbaBuffer[index++] = b;
        rgbaBuffer[index++] = 255;
      }
    }

    final convertedImage = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgbaBuffer.buffer,
      order: img.ChannelOrder.rgba,
    );

    return convertedImage;
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

  String? _getTopFrequency(List<List<String>> recentDetections) {
    if (recentDetections.isEmpty) return null;

    final allDetections = recentDetections.expand((frame) => frame).toList();
    final Map<String, int> freqMap = {};
    for (var label in allDetections) {
      freqMap[label] = (freqMap[label] ?? 0) + 1;
    }
    if (freqMap.isEmpty) return null;
    final sortedEntries = freqMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sortedEntries.take(3).toList();
    final result = top3.map((e) => e.key).join(", ");
    print("Top 3 frequencies: $result");
    return result;
  }

  void _switchMode (bool _nextMode, bool _previousMode) async{
    Vibration.vibrate(duration: 100);
    // Switch mode
    // _tts = ttsService();
    _tts.switchMode();


    setState(() {
      if (_nextMode) {
        currentModeIndex = (currentModeIndex + 1) % modes.length; // next mode
      } else if (_previousMode) {
        currentModeIndex = (currentModeIndex - 1 + modes.length) % modes.length; //previous mode
      }
      _detectedObjects.clear();
      _recognizedText='';

    });
    _tts.speakText('Switch to ${modes[currentModeIndex]}');
    print("⚠️⚠️_detectedObjects is clear: $_detectedObjects");

  }

  @override
  void dispose() {
    _imageStreamSubscription?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _tts.stop();
    super.dispose();
  }

  bool _hasSwipedLeft = false;
  bool _hasSwipedRight = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Speak Sight')),
      body: _isCameraInitialized
          ? GestureDetector(
            // Swipe to switch mode
            onPanStart: (details) {
              _hasSwipedLeft = false;
              _hasSwipedRight = false;
            },
            onPanUpdate: (details) {
              if (details.delta.dx < -10 && !_hasSwipedLeft) {
                _hasSwipedLeft = true;
                _switchMode(true,false);
              }
              if (details.delta.dx > 10 && !_hasSwipedRight) {
                _hasSwipedRight = true;
                _switchMode(false,true);
              }
            },
            onPanEnd: (details) {
              _hasSwipedLeft = false;
              _hasSwipedRight = false;
            },
            
              onLongPressStart: (modes[currentModeIndex] == 'Object Search')? (_) async{ 
                _tts.switchMode();
                _tts.speakText("Listening");
                
                await Future.delayed(const Duration(milliseconds:600));
                Vibration.vibrate(duration: 100);
                setState(() {
                  _isListening = true;
                });
                _stt.startListening();
              }:null,

              onLongPressEnd: (modes[currentModeIndex] == 'Object Search')? (_) async {
                String searchTarget = await _stt.stopListening();
                setState(() {
                  _searchTarget = searchTarget;
                  _isListening = false;
                  });
                if(searchTarget.isNotEmpty){
                  print("🔍 Searching for $searchTarget");
                  _tts.speakText('Searching for $searchTarget');
                  }
              }:null,

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

}