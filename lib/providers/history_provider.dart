import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../core/utils/image_utils.dart';
import '../data/models/history_item.dart';
import '../data/models/translation_result.dart';
import 'shared_preferences_provider.dart';

class HistoryNotifier extends Notifier<List<HistoryItem>> {
  static const _storageKey = 'translation_history';
  static const int _maxHistoryItems = 50; // Cap items to prevent memory bloat and UI lag

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
      } catch (_) {
        // Fallback if decoding fails
      }
    }
    return [];
  }

  Future<void> _saveToStorage(List<HistoryItem> items) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final jsonString = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  Future<void> addHistory(
    XFile image,
    TranslationResult result, {
    Uint8List? croppedImageBytes,
  }) async {
    // Persist temporary image to app documents directory
    final permanentPath = await ImageUtils.persistImageFile(image.path);

    final newItem = HistoryItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      imagePath: permanentPath,
      result: result,
      timestamp: DateTime.now(),
      croppedImageBytes: croppedImageBytes,
    );

    // Add to the beginning of the list and cap at 50 items
    final updated = [newItem, ...state];
    state = updated.length > _maxHistoryItems
        ? updated.sublist(0, _maxHistoryItems)
        : updated;

    await _saveToStorage(state);
  }

  Future<void> deleteHistory(String id) async {
    state = state.where((item) => item.id != id).toList();
    await _saveToStorage(state);
  }

  Future<void> clearHistory() async {
    state = [];
    await _saveToStorage(state);
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, List<HistoryItem>>(() {
  return HistoryNotifier();
});
