import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/history_item.dart';
import '../data/models/translation_result.dart';
import 'shared_preferences_provider.dart';

class HistoryNotifier extends Notifier<List<HistoryItem>> {
  static const _storageKey = 'translation_history';

  @override
  List<HistoryItem> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final historyJsonString = prefs.getString(_storageKey);
    if (historyJsonString != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(historyJsonString);
        return decodedList
            .map((item) => HistoryItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // Fallback if decoding fails
      }
    }
    return [];
  }

  void _saveToStorage(List<HistoryItem> items) {
    final prefs = ref.read(sharedPreferencesProvider);
    final jsonString = jsonEncode(items.map((item) => item.toJson()).toList());
    prefs.setString(_storageKey, jsonString);
  }

  void addHistory(XFile image, TranslationResult result) {
    final newItem = HistoryItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      imagePath: image.path,
      result: result,
      timestamp: DateTime.now(),
    );
    // Add to the beginning of the list to show newest first
    state = [newItem, ...state];
    _saveToStorage(state);
  }

  void deleteHistory(String id) {
    state = state.where((item) => item.id != id).toList();
    _saveToStorage(state);
  }

  void clearHistory() {
    state = [];
    _saveToStorage(state);
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, List<HistoryItem>>(() {
  return HistoryNotifier();
});
