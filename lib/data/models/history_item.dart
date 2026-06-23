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

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id']?.toString() ?? '',
      imagePath: json['image_path']?.toString() ?? '',
      result: TranslationResult.fromJson(json['result'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_path': imagePath,
      'result': result.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
