import 'package:flutter_tts/flutter_tts.dart';

class TtsService{
  final FlutterTts _flutterTts = FlutterTts();

<<<<<<< HEAD
  Future init()async{
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1);
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> speak(String text)async{
    await _flutterTts.speak(text);
=======

  Future<void> initTts() async {
    await _flutterTts.setPitch(1.0);
    // await _flutterTts.setSpeechRate(1.0);
    await _flutterTts.awaitSpeakCompletion(false);
    // await _flutterTts.setQueueMode(0);

  }

  Future<void> speakObject(List<Map<String, dynamic>> detections)async{
    if (detections.isNotEmpty) {
      String speech = detections.map((d) => d['label']).join(', ');
      await _flutterTts.speak("Detected: $speech");
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

>>>>>>> 74100ef227fc01872091574006625add7952112e
  }

  Future<void> stop()async{
    // await _flutterTts.pause();
    await _flutterTts.stop();
    print("✅TTS is stop");
  }
  Future<void> switchMode()async{
    _flutterTts.stop();
    _flutterTts.setQueueMode(0);
    _flutterTts.speak('');
    _flutterTts.stop();
  }
}

