// lib/homepage.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
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
            _tts.setSpeed(0.54);
            setState(() => _detectedObjects = thisResults);
            final found = thisResults.where((obj) {
              final label = (obj['label'] as String).toLowerCase();
              return label == _searchTarget.toLowerCase();
              }).toList();

            if (found.isNotEmpty) {
              final targetObj = found.first;

              final double xCenter = targetObj['denormalizedX'];
              final double yCenter = targetObj['denormalizedY'];
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
        print("⚠️Android Camera Image");
        // _checkCameraFormat(image);
        // _checkUVOrder(image);
        return _convertYUV420ToImage(image);
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
   * 
   * The memory leakage issue on android is caused by this function.
   * Every time the function is called, a new img.Image object is created. 
   * Because this function converts every pixel within the img.Image into RGB format, the resulting img.Image occupies a significant amount of memory.
   * Moreover, new img.Image objects are created faster than the previous ones can be disposed, which causes memory leakage.
   * Unlike <_convertBGRA8888ToImage> for iOS, there is no in-built function to implement the conversion for android.
   * The current solution is to limit how frequently this function is called: it is now called once every 15 frames.
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

  // void _checkUVOrder(CameraImage cameraImage) {

  //   print("🔍 检查UV排列顺序:");
  //   print("U平面前10个字节: ${cameraImage.planes[1].bytes.sublist(0, 10)}");
  //   print("V平面前10个字节: ${cameraImage.planes[2].bytes.sublist(0, 10)}");
    
  //   int sampleSize = 20;
  //   List<int> uvSamples = [];
  //   for (int i = 0; i < sampleSize; i += 2) {
  //     if (i < cameraImage.planes[1].bytes.length && i < cameraImage.planes[2].bytes.length) {
  //       uvSamples.add(cameraImage.planes[2].bytes[i]);
  //       uvSamples.add(cameraImage.planes[1].bytes[i]);
  //     }
  //   }
  //   print("交错采样结果: $uvSamples");
    
  //   // 可以比较NV21的预期输出格式(先V后U)与实际转换结果
  //   print("检查U/V平面的平均值差异:");
  //   double uAvg = cameraImage.planes[1].bytes.reduce((a, b) => a + b) / cameraImage.planes[1].bytes.length;
  //   double vAvg = cameraImage.planes[2].bytes.reduce((a, b) => a + b) / cameraImage.planes[2].bytes.length;
  //   print("U平面平均值: $uAvg");
  //   print("V平面平均值: $vAvg");
  // }

  // Future<img.Image?> _checkCameraFormat(CameraImage cameraImage) async {
  //   try {
  //     // 👉 诊断代码：输出相机格式信息
  //     print("📊 相机格式信息：");
  //     print("- 平面数量: ${cameraImage.planes.length}");
  //     print("- Y平面宽度: ${cameraImage.width}, 高度: ${cameraImage.height}");
  //     for (int i = 0; i < cameraImage.planes.length; i++) {
  //       print("- 平面[$i] 字节数: ${cameraImage.planes[i].bytes.length}");
  //       print("- 平面[$i] 每行字节: ${cameraImage.planes[i].bytesPerRow}");
  //       print("- 平面[$i] 每像素字节: ${cameraImage.planes[i].bytesPerPixel}");
  //     }
      
  //     // 💡 基于诊断信息选择转换方法
  //     if (cameraImage.format.group == ImageFormatGroup.yuv420) {
  //       // 🔍 创建 NV21 格式的数据
  //       print("Camera Format: ${cameraImage.format.group}");
  //     } else if (cameraImage.format.group == ImageFormatGroup.nv21) {
  //       print("Camera Format: ${cameraImage.format.group}");
  //       // 直接使用 NV21 处理
  //     } else {
  //       print("⚠️ 未知的相机格式: ${cameraImage.format.group}");
  //       // 回退到默认处理
  //     }
  //   } catch (e) {
  //     print("❌ YUV420转换错误: $e");
  //     return null;
  //   }
  // }

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

  // Get the top 3 frequency of detected objects
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

  void _switchMode (bool nextMode, bool previousMode) async{
    Vibration.vibrate(duration: 100);
    // Switch mode
    // _tts = ttsService();
    _tts.switchMode();


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
        
            
            onLongPressStart: (_) async{ 
              _tts.stop();
              _tts.speakText("Listening");
              
              await Future.delayed(const Duration(milliseconds:500));
              Vibration.vibrate(duration: 100);
              setState(() {
                _isListening = true;
              });
              _stt.startListening();
            },

            /// TODO: fixed the voice control for switching mode here
            /// Currently not working properly
            onLongPressEnd: (_) async {
              String recognisedText = await _stt.stopListening();
              print("🎤 Recognised Text: $recognisedText");

              if (recognisedText.contains('Next')) {
                print("🔀 Switching to next mode");
                _switchMode(true, false);
                setState(() {_isListening = false;});
                return;
              } else if (recognisedText.contains('Previous')) {
                print("🔀 Switching to previous mode");
                _switchMode(false, true);
                setState(() {_isListening = false;});
                return;
              }

              if (modes[currentModeIndex] == 'Object Search') {
                setState(() {_searchTarget = recognisedText;});
                if (recognisedText.isNotEmpty) {
                  print("🔍 Searching for $recognisedText");
                  _tts.speakText('Searching for $recognisedText');
                } else {
                  print("❌ No search target received");
                }
              }
              setState(() {_isListening = false;});
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


