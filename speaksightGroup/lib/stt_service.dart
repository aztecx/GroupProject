import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

// https://pub.dev/packages/speech_to_text
class SttService {
  final SpeechToText _speechToText = SpeechToText();
  String _lastWords = '';
  bool _speechEnabled = false;

  void init() async {
    _speechEnabled = await _speechToText.initialize();
  }
  
  void startListening() async {
    if (_speechEnabled) {
      await _speechToText.listen(onResult: _onSpeechResult);
    } else {
      print('Speech recognition not available');
    }
  }

  Future<String> stopListening() async {
    await _speechToText.stop();
    return _lastWords;
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
  }
}