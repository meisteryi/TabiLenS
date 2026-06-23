import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/translation_result.dart';
import '../data/services/gemini_service.dart';

import 'history_provider.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

class GeminiNotifier extends AsyncNotifier<TranslationResult?> {
  @override
  Future<TranslationResult?> build() async {
    // Initial state is null (no translation performed yet)
    return null;
  }



  Future<void> translateSelectedBlock(XFile image, String selectedText) async {
    state = const AsyncLoading();
    
    state = await AsyncValue.guard(() async {
      final bytes = await image.readAsBytes();
      final service = ref.read(geminiServiceProvider);
      final result = await service.analyzeSelectedText(bytes, selectedText);
      
      // Save to scan history
      ref.read(historyProvider.notifier).addHistory(image, result);
      
      return result;
    });
  }

  void reset() {
    state = const AsyncData(null);
  }

  void setLoadedResult(TranslationResult result) {
    state = AsyncData(result);
  }
}

final geminiNotifierProvider = AsyncNotifierProvider<GeminiNotifier, TranslationResult?>(() {
  return GeminiNotifier();
});
