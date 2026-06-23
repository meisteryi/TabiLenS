import 'dart:convert';

class TranslationResult {
  final String originalText;
  final String translation;
  final String context;
  final String tip;
  final String orderPhraseJapanese;
  final String orderPhrasePronunciation;
  final String orderPhraseTranslation;
  final String imageKeyword;

  TranslationResult({
    required this.originalText,
    required this.translation,
    required this.context,
    required this.tip,
    required this.orderPhraseJapanese,
    required this.orderPhrasePronunciation,
    required this.orderPhraseTranslation,
    required this.imageKeyword,
  });

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    return TranslationResult(
      originalText: json['original_text']?.toString() ?? '',
      translation: json['translation']?.toString() ?? '',
      context: json['context']?.toString() ?? '',
      tip: json['tip']?.toString() ?? '',
      orderPhraseJapanese: json['order_phrase_japanese']?.toString() ?? '',
      orderPhrasePronunciation:
          json['order_phrase_pronunciation']?.toString() ?? '',
      orderPhraseTranslation:
          json['order_phrase_translation']?.toString() ?? '',
      imageKeyword: json['image_keyword']?.toString() ?? '',
    );
  }

  factory TranslationResult.fromRawJson(String rawJson) {
    try {
      // Handle potential markdown formatting from Gemini (e.g. ```json ... ```)
      String cleanedJson = rawJson.trim();
      if (cleanedJson.startsWith('```')) {
        // Remove leading block
        cleanedJson = cleanedJson.replaceFirst(RegExp(r'^```(json)?'), '');
        // Remove trailing block
        if (cleanedJson.endsWith('```')) {
          cleanedJson = cleanedJson.substring(0, cleanedJson.length - 3);
        }
        cleanedJson = cleanedJson.trim();
      }

      final Map<String, dynamic> parsed =
          json.decode(cleanedJson) as Map<String, dynamic>;
      return TranslationResult.fromJson(parsed);
    } catch (e) {
      // Fallback/Error parsing
      return TranslationResult(
        originalText: '텍스트를 파싱하는 데 실패했습니다.',
        translation: '해석할 수 없는 형식의 응답입니다.',
        context: 'Gemini 응답 원본: \n$rawJson',
        tip: '다시 시도해 보거나 다른 구도로 촬영해 주세요.',
        orderPhraseJapanese: '',
        orderPhrasePronunciation: '',
        orderPhraseTranslation: '',
        imageKeyword: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'original_text': originalText,
      'translation': translation,
      'context': context,
      'tip': tip,
      'order_phrase_japanese': orderPhraseJapanese,
      'order_phrase_pronunciation': orderPhrasePronunciation,
      'order_phrase_translation': orderPhraseTranslation,
      'image_keyword': imageKeyword,
    };
  }
}
