import 'dart:convert';
import 'dart:typed_data';
import 'translation_result.dart';

class HistoryItem {
  final String id;
  final String imagePath;
  final TranslationResult result;
  final DateTime timestamp;
  final Uint8List? croppedImageBytes;

  HistoryItem({
    required this.id,
    required this.imagePath,
    required this.result,
    required this.timestamp,
    this.croppedImageBytes,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    Uint8List? cropBytes;
    if (json['cropped_image_base64'] != null) {
      try {
        cropBytes = base64Decode(json['cropped_image_base64'].toString());
      } catch (_) {}
    }

    return HistoryItem(
      id: json['id']?.toString() ?? '',
      imagePath: json['image_path']?.toString() ?? '',
      result: TranslationResult.fromJson(json['result'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp']?.toString() ?? DateTime.now().toIso8601String()),
      croppedImageBytes: cropBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_path': imagePath,
      'result': result.toJson(),
      'timestamp': timestamp.toIso8601String(),
      if (croppedImageBytes != null)
        'cropped_image_base64': base64Encode(croppedImageBytes!),
    };
  }
}
