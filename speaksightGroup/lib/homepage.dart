// lib/homepage.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:speaksightgroup/text_service.dart';
import 'package:speaksightgroup/tts_service.dart';
import 'package:vibration/vibration.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'bounding_box_painter.dart';
import 'yolo_service.dart';
import 'dart:async';
import 'dart:typed_data';
import 'tts_service.dart';
import 'stt_service.dart';
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
  List<List<String>> _recentDetections = []; //最近3帧的结果
  String _recognizedText = '';
  String _finalText = '';

  // Lookup tables for YUV420 to RGB conversion
  // static late final List<int> _rVTable = _createRVTable();
  // static late final List<int> _gUTable = _createGUTable();
  // static late final List<int> _gVTable = _createGVTable();
  // static late final List<int> _bUTable = _createBUTable();

  bool _isProcessing=false; // ⚠️防止并发处理
  
  // List of modes
  final List<String> modes = [
    'Object Detection',
    'Object Search',
    'Text Recognition'
  ];
  int currentModeIndex = 0;

  // Check the camera permission and initialize the camera
  @override
  void initState() {
    super.initState();
    // _tts.initTts();
    _checkCameraPermission();
    _tts.initTts();

    // Load the YOLO model and Text model
    _yoloService.loadModel();
    _textService.loadModel();

    // Initialize the TTS and STT

    _stt.init();

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
            final thisResults = await _yoloService.runModel(convertedImage);
            // final finalResults = _removeRepeatedObjects(thisResults,_previousDetections);

            // print("1️⃣This result: ${thisResults.map((result) => result['label']).toList()}");
            // print("2️⃣Previous result: ${_previousDetections}");
            // print("3️⃣Final result: $finalResults");

            setState(() => _detectedObjects = thisResults);
            // _tts.speakObject(_detectedObjects);
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
            setState(() => _recognizedText = results);
            // int currentTime = timers['lastSpeak']!.elapsedMilliseconds;
            // if (results.isNotEmpty && currentTime >= 3000) {
            _tts.speakText(_recognizedText);
              // timers['lastSpeak']?.reset();
            // }
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
          // 其他 YUV420 可能用你原先的 _convertYUV420ToImage
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


  /*
  * Adapted from: https://blog.csdn.net/liyuanbhu/article/details/68951683
  * Author: @liyuanbhu
  */

  // ⚠️For Camera on Android OS
  // static img.Image? convertedImage;
  //
  // Future <img.Image?> _convertYUV420ToImage(CameraImage image) async {
  //   if (convertedImage == null || convertedImage!.width != image.width || convertedImage!.height != image.height) {
  //     convertedImage = img.Image(width: image.width, height: image.height);
  //   }
  //   final int width = image.width;
  //   final int height = image.height;
  //   final int uvRowStride = image.planes[1].bytesPerRow;
  //   final int uvPixelStride = image.planes[1].bytesPerPixel!;
  //
  //   // prepare the planes
  //   final yPlane = image.planes[0].bytes;
  //   final uPlane = image.planes[1].bytes;
  //   final vPlane = image.planes[2].bytes;
  //
  //   // final img.Image converted = img.Image(width: width, height: height);
  //
  //   // create lookup tables
  //   final rVTable = _createRVTable();
  //   final gUTable = _createGUTable();
  //   final gVTable = _createGVTable();
  //   final bUTable = _createBUTable();
  //
  //   // handle with 2x2 block
  //   for (int y = 0; y < height; y += 2) {
  //     for (int x = 0; x < width; x += 2) {
  //       // calculate the uv index
  //       final int uvX = (x ~/ 2);
  //       final int uvY = (y ~/ 2);
  //       final int uvIndex = uvY * uvRowStride + uvX * uvPixelStride;
  //       final int u = uPlane[uvIndex];
  //       final int v = vPlane[uvIndex];
  //
  //       // calculate the r, g, b values
  //       final int rAdd = rVTable[v];
  //       final int gAdd = gUTable[u] + gVTable[v];
  //       final int bAdd = bUTable[u];
  //
  //       // set the 2x2 pixel values
  //       for (int dy = 0; dy < 2; dy++) {
  //         final int py = y + dy;
  //         if (py >= height) break;
  //         for (int dx = 0; dx < 2; dx++) {
  //           final int px = x + dx;
  //           if (px >= width) break;
  //           final int yIndex = py * width + px;
  //           final int yValue = yPlane[yIndex];
  //           int r = ((yValue << 10) + rAdd) >> 10;
  //           int g = ((yValue << 10) + gAdd) >> 10;
  //           int b = ((yValue << 10) + bAdd) >> 10;
  //
  //           convertedImage?.setPixelRgba(
  //             px,
  //             py,
  //             r.clamp(0, 255),
  //             g.clamp(0, 255),
  //             b.clamp(0, 255),
  //             255,
  //           );
  //         }
  //       }
  //     }
  //   }
  //   return convertedImage;
  // }
  //
  // // Create lookup tables for YUV420 to RGB conversion
  // static List<int> _createRVTable() {
  //   return List.generate(256, (v) => (1.402 * (v - 128) * 1024).toInt());
  // }
  //
  // static List<int> _createGUTable() {
  //   return List.generate(256, (u) => (-0.344136 * (u - 128) * 1024).toInt());
  // }
  //
  // static List<int> _createGVTable() {
  //   return List.generate(256, (v) => (-0.714136 * (v - 128) * 1024).toInt());
  // }
  //
  // static List<int> _createBUTable() {
  //   return List.generate(256, (u) => (1.772 * (u - 128) * 1024).toInt());
  // }
  Uint8List? _rgbaBuffer;
  img.Image? convertedImage;

  img.Image? _convertYUV420ToImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;

    // final img.Image converted = img.Image(width: width, height: height);
    final neededLength = width * height * 4; // RGBA 4字节
    if (_rgbaBuffer == null || _rgbaBuffer!.length != neededLength) {
      _rgbaBuffer = Uint8List(neededLength);
    }

    // 填充 _rgbaBuffer
    final planeY = image.planes[0].bytes;
    final planeU = image.planes[1].bytes;
    final planeV = image.planes[2].bytes;

    var index = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
        final yValue = planeY[y * width + x];
        final uValue = planeU[uvIndex];
        final vValue = planeV[uvIndex];

        final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
        final g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).clamp(0, 255).toInt();
        final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

        _rgbaBuffer![index++] = r;
        _rgbaBuffer![index++] = g;
        _rgbaBuffer![index++] = b;
        _rgbaBuffer![index++] = 255; // alpha
      }
    }

    if (convertedImage == null ||
    convertedImage!.width != width ||
    convertedImage!.height != height) 
    {
      convertedImage = img.Image(width: width, height: height, numChannels: 4);
    }

    // 用 fromBytes 复用同一个 buffer
    convertedImage = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: _rgbaBuffer!.buffer,
      order: img.ChannelOrder.rgba,
    );
    return convertedImage!;
  }

  img.Image? _convertNV21ToImage(CameraImage image) {
    // NV21: Plane 0 = Y, Plane 1 = VU interleaved
    final width = image.width;
    final height = image.height;

    // 通常情况下：
    //   image.planes[0] 存 Y 分量
    //   image.planes[1] 存 VU 分量 (两个字节一组：V, U, V, U, ...)
    final planeY = image.planes[0];
    final planeVU = image.planes[1];

    final yBytes = planeY.bytes;
    final vuBytes = planeVU.bytes;

    // 新建 / 复用 RGBA buffer
    final neededLength = width * height * 4; // RGBA
    Uint8List rgbaBuffer = Uint8List(neededLength);

    int index = 0;
    for (int y = 0; y < height; y++) {
      // 当前行相对于 planeY 的起始 index
      final yRowStart = y * planeY.bytesPerRow;
      // NV21 中，U/V 的分辨率是 (width/2) x (height/2)，
      // 每两个竖行共用一行 UV 数据
      final uvRowStart = (y >> 1) * planeVU.bytesPerRow;

      for (int x = 0; x < width; x++) {
        // 取 Y
        final yValue = yBytes[yRowStart + x];

        // 计算 UV 在 planeVU 里的位置
        // (x >> 1) 表示每 2 像素共用一组 (V,U)
        // NV21 排列：VU VU VU...
        final uvIndex = uvRowStart + (x >> 1) * 2;
        final vValue = vuBytes[uvIndex + 0];
        final uValue = vuBytes[uvIndex + 1];

        // 和常规的 YUV->RGB 转换公式相同，只是要注意取值顺序
        final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
        final g = (yValue - 0.344136 * (uValue - 128)
            - 0.714136 * (vValue - 128)).clamp(0, 255).toInt();
        final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

        rgbaBuffer[index++] = r;
        rgbaBuffer[index++] = g;
        rgbaBuffer[index++] = b;
        rgbaBuffer[index++] = 255; // alpha
      }
    }

    // 把 RGBA buffer 转成 img.Image
    // 注意，如果你需要重复利用同一个 img.Image 对象，可自行做缓存
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

    String topLabel = freqMap.keys.first;
    int topCount = freqMap[topLabel] ?? 0;

    freqMap.forEach((label, count) {
      if (count > topCount) {
        topLabel = label;
        topCount = count;
      }
    });
    print("过去${recentDetections.length}帧中出现次数最多的label：$topLabel, 次数=$topCount");
    return topLabel;
  }

  List<Map<String, dynamic>> _removeRepeatedObjects(
      List<Map<String, dynamic>> newResults,
      List<Map<String, dynamic>> prevResults,
      ) {
    final finalResults = <Map<String, dynamic>>[];

    for (final newObj in newResults) {
      final newLabel = newObj['label'];
      bool isRepeated = false;

      for (final oldObj in prevResults) {
        if (oldObj['label'] == newLabel) {
          isRepeated = true;
          print("❌<$newLabel> 已存在，删除");
          break;
        }
      }

      if (!isRepeated) {
        finalResults.add(newObj);
      }
    }
    return finalResults;
  }


  void _switchMode () async{
    Vibration.vibrate(duration: 100);
    // Switch mode
    // _tts = ttsService();
    _tts.switchMode();


    setState(() {
      currentModeIndex = (currentModeIndex + 1) % modes.length;
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Speak Sight')),
      body: _isCameraInitialized
          ? GestureDetector(
              onDoubleTap: _switchMode,
              //Swipe left to switch mode
              /*
              onPanStart: (details) {
              _hasSwipedLeft = false;
            },
            onPanUpdate: (details) {
              if (details.delta.dx < -10 && !_hasSwipedLeft) {
                _hasSwipedLeft = true;
                _switchMode();
              }
            },
            onPanEnd: (details) {
              _hasSwipedLeft = false;
            },
            */
              onLongPressStart: (_) => _stt.startListening(),
              onLongPressEnd: (_) async {
                String finalText = await _stt.stopListening();
                setState(() {
                  _finalText = finalText;
                });
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