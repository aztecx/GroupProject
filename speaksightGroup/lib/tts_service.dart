import 'package:flutter_tts/flutter_tts.dart';

class TtsService{
  final FlutterTts _flutterTts = FlutterTts();

  Future init()async{
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1);
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> speak(String text)async{
    await _flutterTts.speak(text);
  }

  Future<void> stop()async{
    await _flutterTts.stop();
  }
}

