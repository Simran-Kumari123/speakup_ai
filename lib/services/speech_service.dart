import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isInitializing = false;
  Completer<bool>? _initCompleter;

  double _lastLevel = 0.0;

  bool get isInitialized => _isInitialized;
  bool get isListening => _speech.isListening;
  double get lastLevel => _lastLevel;

  /// Initializes the speech engine safely.
  /// If already initializing, waits for the current process.
  Future<bool> init({
    Function(String)? onStatus,
    Function(dynamic)? onError,
  }) async {
    if (_isInitialized) return true;
    
    if (_isInitializing) {
      return _initCompleter?.future ?? Future.value(false);
    }

    _isInitializing = true;
    _initCompleter = Completer<bool>();

    try {
      if (!kIsWeb) {
        debugPrint('🎙️ Checking microphone permission...');
        final status = await Permission.microphone.status;
        debugPrint('🎙️ Current microphone status: $status');
        if (!status.isGranted) {
          debugPrint('🎙️ Requesting microphone permission...');
          final result = await Permission.microphone.request();
          debugPrint('🎙️ Microphone request result: $result');
          if (!result.isGranted) {
            debugPrint('❌ Microphone permission denied');
            _isInitializing = false;
            _initCompleter!.complete(false);
            return false;
          }
        }
      }

      debugPrint('🎙️ Initializing speech engine...');
      final success = await _speech.initialize(
        onStatus: (status) {
          if (onStatus != null) onStatus(status);
          notifyListeners();
        },
        onError: (error) {
          if (onError != null) onError(error);
          notifyListeners();
        },
      );

      _isInitialized = success;
      _initCompleter!.complete(success);
    } catch (e) {
      debugPrint('SpeechService Init Error: $e');
      _initCompleter!.complete(false);
    } finally {
      _isInitializing = false;
    }

    return _isInitialized;
  }

  Future<void> listen({
    required Function(String text, bool isFinal) onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    bool partialResults = true,
    Function(double)? onSoundLevelChange,
  }) async {
    if (!_isInitialized) {
      final ok = await init();
      if (!ok) return;
    }

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
        notifyListeners();
      },
      listenFor: listenFor ?? const Duration(seconds: 30),
      pauseFor: pauseFor ?? const Duration(seconds: 3),
      localeId: localeId ?? 'en_US',
      partialResults: partialResults,
      onSoundLevelChange: (level) {
        _lastLevel = level;
        if (onSoundLevelChange != null) onSoundLevelChange(level);
        notifyListeners();
      },
    );
    notifyListeners();
  }

  Future<void> stop() async {
    await _speech.stop();
    notifyListeners();
  }

  Future<void> cancel() async {
    await _speech.cancel();
    notifyListeners();
  }

  /// Maps technical STT error codes to user-friendly messages.
  static String getFriendlyError(dynamic error) {
    if (error is! SpeechRecognitionError) return 'An unexpected voice error occurred.';
    
    switch (error.errorMsg) {
      case 'error_no_match':
        return 'I didn\'t catch that. Please try again!';
      case 'error_speech_timeout':
        return 'It went quiet! Feel free to try again whenever you\'re ready.';
      case 'error_network':
        return 'Network issues. Please check your connection.';
      case 'error_client':
        return 'The mic engine is having trouble. Please check permissions or restart.';
      case 'error_audio':
        return 'Microphone is busy with another app. Please close other voice apps.';
      case 'error_busy':
        return 'The voice engine is a bit busy. One moment!';
      case 'error_not_initialized':
        return 'The mic isn\'t ready yet.';
      default:
        return 'Mic error: ${error.errorMsg}';
    }
  }
}
