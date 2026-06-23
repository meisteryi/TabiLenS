import 'translation_result.dart';

class HistoryItem {
  final String id;
  final String imagePath;
  final TranslationResult result;
  final DateTime timestamp;

  HistoryItem({
    required this.id,
    required this.imagePath,
    required this.result,
    required this.timestamp,
  });
}
