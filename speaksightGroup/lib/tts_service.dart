import 'dart:ui';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService{
  final FlutterTts _flutterTts = FlutterTts();



  Future<void> init() async {
    await _flutterTts.setPitch(1.0);
    // await _flutterTts.setSpeechRate(1.0);
    await _flutterTts.awaitSpeakCompletion(false);
    // await _flutterTts.setQueueMode(0);
    await _flutterTts.setLanguage('en-GB');

  }

  Future<void> speakObject(List<Map<String, dynamic>> detections)async{
    if (detections.isNotEmpty) {
      String object = detections.map((d) => d['label']).join(', ');
      await _flutterTts.speak(object);
    }

  }

  Future<void> speakText(String text)async{
    if (text!='') {
      await _flutterTts.speak(text);
    }
  }
  
  Future<void> pause()async{
    // await _flutterTts.pause();
    await _flutterTts.pause();
  }
  Future<void> setSpeed(double speed) async {
    await _flutterTts.setSpeechRate(speed);
    // print("✅TTS speed set to $speed");
  }

  Future<void> stop() async {
    // await _flutterTts.pause();
    await _flutterTts.stop();
    // print("✅TTS is stop");
  }

  Future<void> forceStop()async{
    await _flutterTts.stop();
    await _flutterTts.setQueueMode(0);
    await _flutterTts.speak('');
    await _flutterTts.stop();
    await _flutterTts.setQueueMode(1);
    await Future.delayed(Duration(milliseconds: 100));
  }

    Future<void> exportToMP3(String text, String fileName) async {
    try {
      String savePath = '${Directory.current.path}/assets/onboarding';
      
      String filePath = '$savePath/${fileName}_${DateTime.now().millisecondsSinceEpoch}.mp3';
      
      // Configure TTS for synthesis
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.awaitSynthCompletion(true);
      
      // Some TTS engines support direct saving
      bool success = await _flutterTts.synthesizeToFile(text, filePath);
      
      if (success) {
        print('Audio saved successfully to: $filePath');
      } else {
        print('Failed to save audio file');
      }
    } catch (e) {
      print('Error exporting to MP3: $e');
    }
  }
}

