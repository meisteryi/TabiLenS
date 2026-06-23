import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsNotifier extends StateNotifier<bool> {
  final FlutterTts _flutterTts = FlutterTts();

  TtsNotifier() : super(false) {
    _initTts();
  }

  void _initTts() {
    _flutterTts.setStartHandler(() {
      state = true;
    });

    _flutterTts.setCompletionHandler(() {
      state = false;
    });

    _flutterTts.setCancelHandler(() {
      state = false;
    });

    _flutterTts.setErrorHandler((message) {
      debugPrint('TTS Error: $message');
      state = false;
    });
  }

  Future<void> speak(String text) async {
    if (state) {
      await stop();
    }

    try {
      // Set to Japanese language
      await _flutterTts.setLanguage('ja-JP');
      // Set a slightly slower speech rate for clarity in foreign languages
      await _flutterTts.setSpeechRate(0.4);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error speaking text: $e');
      state = false;
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      state = false;
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}

final ttsProvider = StateNotifierProvider.autoDispose<TtsNotifier, bool>((ref) {
  return TtsNotifier();
});
