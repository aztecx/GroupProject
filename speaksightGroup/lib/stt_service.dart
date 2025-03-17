import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';

// https://pub.dev/packages/speech_to_text
class SttService {
  final SpeechToText _speechToText = SpeechToText();
  String _lastWords = '';
  bool _speechEnabled = false;
  bool _isListening = false;

  void init() async {
    PermissionStatus status = await Permission.microphone.request();
    if (status.isGranted) {
      _speechEnabled = await _speechToText.initialize(debugLogging: true);
      print('STT initialized: $_speechEnabled');
    } else {
      print('Microphone permission denied');
      _speechEnabled = false;
    }
  }
  
  void startListening() async {
    if (_speechEnabled) {
      await _speechToText.listen(onResult: _onSpeechResult);
      _isListening = true;
    } else {
      print('Speech recognition not available');
    }
  }

  // ToFix: stopListening() method doesn't work on android
  Future<String> stopListening() async {
    if (_speechToText.isListening) {
      try {
        await _speechToText.stop();
        print('Stopped listening');
        await Future.delayed(const Duration(milliseconds: 200));
        _isListening = false;
        print('Final recognized words: $_lastWords');
        return _lastWords;
      } catch (e) {
        print('Error stopping speech recognition: $e');
        return '';
      }
    } else {
      _isListening = false;
      return _lastWords;
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    
    print('Recognized: $_lastWords');
  }
}