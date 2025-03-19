// lib/homepage.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:speaksightgroup/text_service.dart';
import 'package:speaksightgroup/tts_service.dart';
import 'package:speaksightgroup/stt_service.dart';
import 'package:vibration/vibration.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:yuv_converter/yuv_converter.dart';
import 'bounding_box_painter.dart';
import 'yolo_service.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:speaksightgroup/onboarding.dart';

/// Homepage provides the main camera functionality of the application.
///
/// This is the core functional page that enables:
/// - Object detection with audio feedback
/// - Text recognition with spoken output
/// - Object search with directional guidance
/// - Voice command input for controls
/// - Gesture controls for navigation
///
/// The page uses the device camera to capture real-time video and
/// processes frames to identify objects or text, providing audio
/// feedback to assist visually impaired users.
class Homepage extends StatefulWidget {
  @override
  _HomepageState createState() => _HomepageState();
}

/// State for Homepage handling camera processing and detection features.
///
/// This state manages:
/// - Camera initialization and frame processing
/// - Multiple detection modes (Object Detection, Text Recognition, Object Search)
/// - Gesture control handling
/// - Voice command processing
/// - Text-to-speech feedback
class _HomepageState extends State<Homepage> {
  /// Performance monitoring stopwatches for different processing stages.
  final timers = <String, Stopwatch>{
    'base': Stopwatch(),
    'runModel': Stopwatch(),
    'lastSpeak':Stopwatch()..start(),

  };

  /// Platform detection flags for device-specific code paths.
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
  String _searchTarget = '';

  bool _isProcessing=false; // ⚠️防止并发处理
  bool _pauseDetection = false;
  
  // List of modes
  final List<String>  modes = [
    'Object Detection',
    'Object Search',
    'Text Recognition'
  ];
  int currentModeIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
    _tts.init();
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
  int _frameLimit = 15; // ⚠️frame rate control

  void _startDetectionLoop() async {
    // check if the camera is initialized
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    // Start the image stream
    await _cameraController!.startImageStream((CameraImage image) async {
      
      if(_pauseDetection){
            return;
          }
      // Limit the frame rate
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

        // Process image based on current mode
        if (convertedImage != null) {
          if (modes[currentModeIndex] == 'Object Detection') {
            final thisResults = await _yoloService.runModel(convertedImage);
            _tts.setSpeed(0.5);

            setState(() => _detectedObjects = thisResults);
            if(thisResults.isNotEmpty){
              final objectsInThisFrame = thisResults.map((obj) => obj['label'] as String).toList();
              _recentDetections.add(objectsInThisFrame);
              if(_recentDetections.length > 10){ // Keep last 10 frames
                _recentDetections.removeAt(0);
              }

              final topFrequencyObj = _getTopFrequency(_recentDetections);
              if(timers['lastSpeak']!=null) {
                int currentTime = timers['lastSpeak']!.elapsedMilliseconds;
                // print("Since lastSpeak: $currentTime");
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
            _tts.setSpeed(0.54);
            setState(() => _detectedObjects = thisResults);
            final found = thisResults.where((obj) {
              final label = (obj['label'] as String).toLowerCase();
              return label == _searchTarget.toLowerCase();
              }).toList();

            // Provide directional guidance if target is found
            if (found.isNotEmpty) {
              final targetObj = found.first;

              // Calculate object position relative to screen
              final double xCenter = targetObj['denormalizedX'];
              final double yCenter = targetObj['denormalizedY'];
              final screenWidth = MediaQuery.of(context).size.width;
              final screenHeight = MediaQuery.of(context).size.height;
              final double halfW = screenWidth / 2;
              final double halfH = screenHeight / 2;

              // Determine quadrant location
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

  /// Converts camera frames to the img.Image format for processing.
  /// 
  /// This method dispatches to platform-specific conversion methods
  /// since Android and iOS use different image formats from the camera.
  /// 
  /// Parameters:
  ///   image: The camera image to convert
  /// 
  /// Returns:
  ///   An img.Image object or null if conversion fails
  Future<img.Image?> _convertCameraImage(CameraImage image) async {
    try {
      // final int width = image.width;
      // final int height = image.height;

      if (isAndroid) {
        // print("⚠️Android Camera Image");
        return _convertYUV420ToImage(image);
      } else if (isIOS) {
        // print("⚠️iOS Camera Image");
        return _convertBGRA8888ToImage(image);
        // return null;
      }
      return null;
    } catch (e) {
      // print("❌ Image conversion error: $e");
      return null;
    }
  }
  /// Reused image instance to reduce memory allocation.
  img.Image? convertedImage;



  /// Converts YUV420 format camera images to RGB format for Android.
  /// Adapted from: https://gist.github.com/Alby-o/fe87e35bc21d534c8220aed7df028e03
  /// Author: @ Alby-o
  /// 
  /// This is an optimized implementation that:
  /// 1. Reuses image buffers when possible
  /// 2. Performs YUV to RGB color space conversion
  /// 3. Rotates the image to match screen orientation
  /// 
  ///    Note: 
  ///     The memory leakage issue on android is caused by this function.
  ///     Every time the function is called, a new img.Image object is created. 
  ///     Because this function converts every pixel within the img.Image into RGB format, the resulting img.Image occupies a significant amount of memory.
  ///     Moreover, new img.Image objects are created faster than the previous ones can be disposed, which causes memory leakage.
  ///     Unlike <_convertBGRA8888ToImage> for iOS, there is no in-built function to implement the conversion for android.
  ///     The current solution is to limit how frequently this function is called: it is now called once every 15 frames.
  /// 
  /// Parameters:
  ///   cameraImage: The YUV format camera image
  /// 
  /// Returns:
  ///   An RGB format image suitable for processing
  img.Image _convertYUV420ToImage(CameraImage cameraImage) {
    final imageWidth = cameraImage.width;
    final imageHeight = cameraImage.height;

    // Reuse image buffer when possible to reduce memory allocations
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
    return img.copyRotate(convertedImage!, angle: 90);
  }

  /// Converts BGRA8888 format camera images to RGB format for iOS.
  /// 
  /// Uses the img.Image library's built-in conversion capabilities
  /// which are more efficient than manual pixel conversion.
  /// 
  /// Parameters:
  ///   image: The BGRA format camera image
  /// 
  /// Returns:
  ///   An RGB format image suitable for processing
  img.Image _convertBGRA8888ToImage(CameraImage image) {
    final bytes = Uint8List.fromList(image.planes[0].bytes);
    return img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  /// Analyzes recent detections to find most frequently detected objects.
  /// 
  /// This method:
  /// 1. Flattens all detections from recent frames
  /// 2. Counts frequency of each object label
  /// 3. Sorts by frequency (highest first)
  /// 4. Returns top 3 most frequent objects
  /// 
  /// This helps filter out random false detections by prioritizing
  /// objects that consistently appear across multiple frames.
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
    // print("Top 3 frequencies: $result");
    return result;
  }

  /// Switches between app modes (Object Detection, Object Search, Text Recognition).
  /// 
  /// Provides haptic feedback, clears previous detection results,
  /// and announces the new mode via text-to-speech.
  /// 
  /// Parameters:
  ///   nextMode: If true, advance to the next mode
  ///   previousMode: If true, go to the previous mode
  void _switchMode (bool nextMode, bool previousMode) async{
    Vibration.vibrate(duration: 100);
    // Switch mode
    // _tts = ttsService();
    _tts.stop();
    setState(() {
      if (nextMode) {
        currentModeIndex = (currentModeIndex + 1) % modes.length; // next mode
      } else if (previousMode) {
        currentModeIndex = (currentModeIndex - 1 + modes.length) % modes.length; //previous mode
      }
      _detectedObjects.clear();
      _recognizedText='';

    });
    _tts.speakText('Switch to ${modes[currentModeIndex]}');
    // print("⚠️⚠️_detectedObjects is clear: $_detectedObjects");

  }

  /// Opens the tutorial/onboarding page.
  /// 
  /// Stops any ongoing speech, transitions to the tutorial page
  /// with a fade animation, and ensures speech is stopped when
  /// returning from the tutorial.
  void _openTutorial() {
    // Stop current TTS
    _tts.stop();
    // Pause detection
    setState(() {
      _pauseDetection = true;
    });
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _imageStreamSubscription?.cancel();
      _cameraController!.stopImageStream();
    }
    
    // Navigate to onboarding page
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => OnboardingPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ).then((_) {
      _tts.stop();
      // When returning from onboarding, resume detection
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        _startDetectionLoop();
      }
      setState(() {
        _pauseDetection = false;
      });
      
    });
  }

  @override
  void dispose() {
    _imageStreamSubscription?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _tts.forceStop();
    super.dispose();
  }

  /// Swipe gesture tracking flags.
  bool _hasSwipedLeft = false;
  bool _hasSwipedRight = false;
  bool _hasSwipedUp = false;
  // bool _hasSwipedDown = false;
  double _swipeUpDistance = 0;
  
  /// Builds the main UI for the homepage.
  /// 
  /// Creates a page with:
  /// 1. Camera preview
  /// 2. Bounding box overlays for detected objects
  /// 3. Mode indicator
  /// 4. Gesture detectors for swipe navigation and voice commands
  /// 
  /// The UI is designed to work primarily through gestures and voice
  /// for visually impaired users, with minimal reliance on visual elements.
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
              _hasSwipedUp = false;
              // _hasSwipedDown = false;
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
              if(details.delta.dy < -2){
                _hasSwipedUp = true;
                _swipeUpDistance -= details.delta.dy;
                if(_swipeUpDistance > 50 && !_hasSwipedUp){
                  HapticFeedback.mediumImpact();
                  _hasSwipedUp=true;
                }
              }
            },
            onPanEnd: (details) {
              _hasSwipedLeft = false;
              _hasSwipedRight = false;
              if(_swipeUpDistance > 100){
                _openTutorial();
              }
              _swipeUpDistance = 0;
              _hasSwipedUp = false;
            },
        
            onLongPressStart: (_) async{ 
              _tts.stop();
              _tts.speakText("Listening");
              
              await Future.delayed(const Duration(milliseconds:500));
              Vibration.vibrate(duration: 100);
              setState(() {
                _pauseDetection = true;
              });
              _stt.startListening();
            },

            onLongPressEnd: (_) async {
              String recognisedSpeech = await _stt.stopListening();
              print("🎤 Recognised Text: $recognisedSpeech");

              if (recognisedSpeech.contains('Next')||recognisedSpeech.contains('next')) {
                print("🔀 Switching to next mode");
                _switchMode(true, false);
                setState(() {_pauseDetection = false;});
                recognisedSpeech = '';
                return;
              } else if (recognisedSpeech.contains('Previous')||recognisedSpeech.contains('previous')) {
                print("🔀 Switching to previous mode");
                _switchMode(false, true);
                setState(() {_pauseDetection = false;});
                recognisedSpeech = '';
                return;
              }

              if (modes[currentModeIndex] == 'Object Search') {
                setState(() {_searchTarget = recognisedSpeech;});
                if (recognisedSpeech.isNotEmpty) {
                  print("🔍 Searching for $recognisedSpeech");
                  _tts.speakText('Searching for $recognisedSpeech');
                } else {
                  print("❌ No search target received");
                }
              }
              setState(() {_pauseDetection = false;});
              recognisedSpeech = '';
            },

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


