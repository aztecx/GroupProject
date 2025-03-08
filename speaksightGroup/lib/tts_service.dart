import 'package:flutter_tts/flutter_tts.dart';

class ttsService{
  final FlutterTts _flutterTts = FlutterTts();


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

