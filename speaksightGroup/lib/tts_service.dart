import 'package:flutter_tts/flutter_tts.dart';

class ttsService{
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> speak(String text)async{
    await _flutterTts.speak(text);
  }

  Future<void> stop()async{
    await _flutterTts.stop();
  }
}

