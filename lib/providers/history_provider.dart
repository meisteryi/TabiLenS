import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/history_item.dart';
import '../data/models/translation_result.dart';

class HistoryNotifier extends Notifier<List<HistoryItem>> {
  @override
  List<HistoryItem> build() {
    return [];
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
  }

  void deleteHistory(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void clearHistory() {
    state = [];
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, List<HistoryItem>>(() {
  return HistoryNotifier();
});
