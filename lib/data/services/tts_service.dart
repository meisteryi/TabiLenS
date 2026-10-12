import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../providers/language_provider.dart';

class TtsNotifier extends StateNotifier<bool> {
  final FlutterTts _flutterTts = FlutterTts();
  final Ref? ref;

  TtsNotifier([this.ref]) : super(false) {
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

  String _getTtsLocaleForMode(LanguageMode mode) {
    switch (mode) {
      case LanguageMode.french:
        return 'fr-FR';
      case LanguageMode.spanish:
        return 'es-ES';
      case LanguageMode.english:
        return 'en-US';
      case LanguageMode.chinese:
        return 'zh-CN';
      case LanguageMode.japanese:
        return 'ja-JP';
    }
  }

  Future<void> speak(String text, {String? localeCode}) async {
    if (state) {
      await stop();
    }

    try {
      String targetLocale = localeCode ?? 'ja-JP';
      if (localeCode == null && ref != null) {
        try {
          final activeLang = ref!.read(languageProvider);
          targetLocale = _getTtsLocaleForMode(activeLang);
        } catch (_) {}
      }

      await _flutterTts.setLanguage(targetLocale);
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
  return TtsNotifier(ref);
});
