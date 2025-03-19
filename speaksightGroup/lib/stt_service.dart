import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';

/// https://pub.dev/packages/speech_to_text
/// 
/// SttService provides speech-to-text functionality for the application.
/// 
/// This service handles speech recognition by requesting microphone permissions,
/// initializing the speech recognition engine, and providing methods to start and stop
/// listening for user speech input. It's primarily used to enable voice commands
/// and search functionality for visually impaired users.
class SttService {
  final SpeechToText _speechToText = SpeechToText();
  String _lastWords = '';
  bool _speechEnabled = false;
  bool _isListening = false;

  void init() async {
    PermissionStatus status = await Permission.microphone.request();
    _speechEnabled = await _speechToText.initialize(debugLogging: true);
    print('STT initialized: $_speechEnabled');
  }
  
  /// Starts listening for speech input.
  /// 
  /// Begins the speech recognition process if speech recognition is enabled.
  /// Updates the [_isListening] flag to indicate active listening.
  /// Recognition results are handled by the [_onSpeechResult] callback.
  void startListening() async {
    if (_speechEnabled) {
      await _speechToText.listen(onResult: _onSpeechResult);
      _isListening = true;
    } else {
      print('Speech recognition not available');
    }
  }

  /// Stops listening for speech input and returns the last recognized word.
  /// 
  /// Attempts to stop the speech recognition service and extracts the [last word]
  /// from the recognized speech. This is particularly useful for command recognition.
  /// 
  /// Returns:
  ///   A [String] containing the last word recognized, or an empty string if no words
  ///   were recognized or an error occurred.
  /// 
  /// Note: There is a known issue with this method not working properly on some Android devices.
  Future<String> stopListening() async {
    if (_speechToText.isListening) {
      try {
        await _speechToText.stop();
        print('Stopped listening');
        await Future.delayed(const Duration(milliseconds: 200));
        _isListening = false;
        List<String> words = _lastWords.trim().split(RegExp(r'\s+'));
        String lastWord = words.isNotEmpty ? words.last : '';
        print('Final recognized word: $lastWord');
        return lastWord;
      } catch (e) {
        print('Error stopping speech recognition: $e');
        return '';
      }
    } else {
      _isListening = false;
      List<String> words = _lastWords.trim().split(RegExp(r'\s+'));
      return words.isNotEmpty ? words.last : '';
    }
  }

  /// Callback function for speech recognition results.
  /// 
  /// Updates [_lastWords] with the recognized speech text when results
  /// are available from the speech recognition engine.
  /// 
  /// Parameters:
  ///   result: A [SpeechRecognitionResult] object containing the recognized speech.
  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    
    print('Recognized: $_lastWords');
  }
}