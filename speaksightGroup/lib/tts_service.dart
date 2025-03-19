import 'dart:ui';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';



/// TtsService provides text-to-speech functionality for the application.
/// 
/// This service handles speech synthesis by initializing the TTS engine,
/// converting text to speech, and managing speech playback. It's primarily 
/// used to provide audio feedback about detected objects and text, making
/// the application accessible for visually impaired users.
class TtsService{
  final FlutterTts _flutterTts = FlutterTts();
  Future<void> init() async {
    await _flutterTts.setPitch(1.0);
    // await _flutterTts.setSpeechRate(1.0);
    await _flutterTts.awaitSpeakCompletion(false);
    // await _flutterTts.setQueueMode(0);
    await _flutterTts.setLanguage('en-GB');

  }

  /// Speaks the provided text.
  /// 
  /// Takes a string and passes it to the TTS engine for speech synthesis.
  /// Only speaks if the text is not empty.
  Future<void> speakText(String text)async{
    if (text!='') {
      await _flutterTts.speak(text);
    }
  }

  /// Pauses the current speech playback.
  /// 
  /// Temporarily halts speech output, which can be resumed later.
  Future<void> pause()async{
    // await _flutterTts.pause();
    await _flutterTts.pause();
  }

  /// Sets the speech rate (speed).
  /// 
  /// Adjusts how fast the text is spoken by the TTS engine.
  /// 1.0 is fastest and 0.0 is slowest.
  Future<void> setSpeed(double speed) async {
    await _flutterTts.setSpeechRate(speed);
    // print("✅TTS speed set to $speed");
  }

  /// Stops the current speech playback.
  /// 
  /// Completely stops speech output, which cannot be resumed.
  Future<void> stop() async {
    // await _flutterTts.pause();
    await _flutterTts.stop();
    // print("✅TTS is stop");
  }


  /// Forcefully stops all speech and resets the TTS engine.
  /// 
  /// This method ensures all speech is immediately stopped by:
  /// 1. Stopping current speech
  /// 2. Setting queue mode to 0 (flush)
  /// 3. Speaking an empty string
  /// 4. Stopping again
  /// 5. Resetting queue mode to 1 (normal)
  /// 
  /// Used in situations where a complete reset of the speech system is needed.
  Future<void> forceStop()async{
    await _flutterTts.stop();
    await _flutterTts.setQueueMode(0);
    await _flutterTts.speak('');
    await _flutterTts.stop();
    await _flutterTts.setQueueMode(1);
    await Future.delayed(Duration(milliseconds: 100));
  }

}

