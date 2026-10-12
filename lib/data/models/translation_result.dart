import 'dart:convert';

class TranslationResult {
  final String originalText;
  final String translation;
  final String context;
  final String tip;
  final String allergyInfo;
  final String orderPhraseJapanese;
  final String orderPhrasePronunciation;
  final String orderPhraseTranslation;
  final String imageKeyword;
  final List<TranslationResult> items;

  TranslationResult({
    required this.originalText,
    required this.translation,
    required this.context,
    required this.tip,
    this.allergyInfo = '',
    required this.orderPhraseJapanese,
    required this.orderPhrasePronunciation,
    required this.orderPhraseTranslation,
    required this.imageKeyword,
    List<TranslationResult>? items,
  }) : items = items ?? [];

  /// Returns all detected items, or a single-element list with this if only 1 item
  List<TranslationResult> get allItems => items.isNotEmpty ? items : [this];

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    List<TranslationResult> parsedItems = [];
    if (rawItems is List && rawItems.isNotEmpty) {
      parsedItems = rawItems
          .whereType<Map<String, dynamic>>()
          .map((e) => TranslationResult.fromJson(e))
          .toList();
    }

    final originalText = json['original_text']?.toString() ??
        (parsedItems.isNotEmpty ? parsedItems.first.originalText : '');
    final translation = json['translation']?.toString() ??
        (parsedItems.isNotEmpty ? parsedItems.first.translation : '');
    final context = json['context']?.toString() ??
        (parsedItems.isNotEmpty ? parsedItems.first.context : '');
    final tip = json['tip']?.toString() ??
        (parsedItems.isNotEmpty ? parsedItems.first.tip : '');
    final allergyInfo = json['allergy_info']?.toString() ??
        json['allergens']?.toString() ??
        (parsedItems.isNotEmpty ? parsedItems.first.allergyInfo : '');
    final orderPhrase = (json['order_phrase'] ??
            json['order_phrase_local'] ??
            json['order_phrase_japanese'])
        ?.toString() ??
        (parsedItems.isNotEmpty ? parsedItems.first.orderPhraseJapanese : '');
    final orderPhrasePronunciation =
        json['order_phrase_pronunciation']?.toString() ??
            (parsedItems.isNotEmpty
                ? parsedItems.first.orderPhrasePronunciation
                : '');
    final orderPhraseTranslation =
        json['order_phrase_translation']?.toString() ??
            (parsedItems.isNotEmpty
                ? parsedItems.first.orderPhraseTranslation
                : '');
    final imageKeyword = json['image_keyword']?.toString() ??
        (parsedItems.isNotEmpty ? parsedItems.first.imageKeyword : '');

    return TranslationResult(
      originalText: originalText,
      translation: translation,
      context: context,
      tip: tip,
      allergyInfo: allergyInfo,
      orderPhraseJapanese: orderPhrase,
      orderPhrasePronunciation: orderPhrasePronunciation,
      orderPhraseTranslation: orderPhraseTranslation,
      imageKeyword: imageKeyword,
      items: parsedItems.isNotEmpty ? parsedItems : null,
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

      final dynamic parsed = json.decode(cleanedJson);
      if (parsed is List) {
        final list = parsed
            .whereType<Map<String, dynamic>>()
            .map((e) => TranslationResult.fromJson(e))
            .toList();
        if (list.isNotEmpty) {
          final first = list.first;
          return TranslationResult(
            originalText: first.originalText,
            translation: first.translation,
            context: first.context,
            tip: first.tip,
            allergyInfo: first.allergyInfo,
            orderPhraseJapanese: first.orderPhraseJapanese,
            orderPhrasePronunciation: first.orderPhrasePronunciation,
            orderPhraseTranslation: first.orderPhraseTranslation,
            imageKeyword: first.imageKeyword,
            items: list,
          );
        }
      } else if (parsed is Map<String, dynamic>) {
        return TranslationResult.fromJson(parsed);
      }

      throw Exception('Unexpected JSON structure');
    } catch (e) {
      // Fallback/Error parsing
      return TranslationResult(
        originalText: '텍스트를 파싱하는 데 실패했습니다.',
        translation: '해석할 수 없는 형식의 응답입니다.',
        context: 'Gemini 응답 원본: \n$rawJson',
        tip: '다시 시도해 보거나 다른 구도로 촬영해 주세요.',
        allergyInfo: '',
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
      'allergy_info': allergyInfo,
      'order_phrase_japanese': orderPhraseJapanese,
      'order_phrase_pronunciation': orderPhrasePronunciation,
      'order_phrase_translation': orderPhraseTranslation,
      'image_keyword': imageKeyword,
      if (items.isNotEmpty) 'items': items.map((e) => e.toJson()).toList(),
    };
  }
}
