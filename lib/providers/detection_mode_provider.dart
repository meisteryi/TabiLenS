import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_preferences_provider.dart';

enum DetectionMode {
  onDevice,
  cloudAi,
}

class DetectionModeNotifier extends Notifier<DetectionMode> {
  static const _storageKey = 'text_detection_mode';

  @override
  DetectionMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedMode = prefs.getString(_storageKey);
    if (savedMode == DetectionMode.onDevice.name) {
      return DetectionMode.onDevice;
    } else if (savedMode == DetectionMode.cloudAi.name) {
      return DetectionMode.cloudAi;
    }
    // Default mode: cloudAi (Gemini)
    return DetectionMode.cloudAi;
  }

  Future<void> setDetectionMode(DetectionMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_storageKey, mode.name);
  }
}

final detectionModeProvider = NotifierProvider<DetectionModeNotifier, DetectionMode>(() {
  return DetectionModeNotifier();
});
