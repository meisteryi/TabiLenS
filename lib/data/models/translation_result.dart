import 'dart:convert';

class TranslationResult {
  final String? _originalText;
  final String? _translation;
  final String? _price;
  final String? _context;
  final String? _tip;
  final String? _allergyInfo;
  final String? _orderPhraseJapanese;
  final String? _orderPhrasePronunciation;
  final String? _orderPhraseTranslation;
  final String? _imageKeyword;
  final List<TranslationResult>? _items;

  String get originalText => _originalText ?? '';
  String get translation => _translation ?? '';
  String get price => _price ?? '';
  String get context => _context ?? '';
  String get tip => _tip ?? '';
  String get allergyInfo => _allergyInfo ?? '';
  String get orderPhraseJapanese => _orderPhraseJapanese ?? '';
  String get orderPhrasePronunciation => _orderPhrasePronunciation ?? '';
  String get orderPhraseTranslation => _orderPhraseTranslation ?? '';
  String get imageKeyword => _imageKeyword ?? '';
  List<TranslationResult> get items => _items ?? [];

  TranslationResult({
    String? originalText,
    String? translation,
    String? price,
    String? context,
    String? tip,
    String? allergyInfo,
    String? orderPhraseJapanese,
    String? orderPhrasePronunciation,
    String? orderPhraseTranslation,
    String? imageKeyword,
    List<TranslationResult>? items,
  })  : _originalText = originalText ?? '',
        _translation = translation ?? '',
        _price = price ?? '',
        _context = context ?? '',
        _tip = tip ?? '',
        _allergyInfo = allergyInfo ?? '',
        _orderPhraseJapanese = orderPhraseJapanese ?? '',
        _orderPhrasePronunciation = orderPhrasePronunciation ?? '',
        _orderPhraseTranslation = orderPhraseTranslation ?? '',
        _imageKeyword = imageKeyword ?? '',
        _items = items ?? [];

  /// Returns all detected items, or a single-element list with this if only 1 item
  List<TranslationResult> get allItems => items.isNotEmpty ? items : [this];

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    List<TranslationResult> parsedItems = [];
    if (rawItems is List && rawItems.isNotEmpty) {
      for (final e in rawItems) {
        if (e is Map<String, dynamic>) {
          parsedItems.add(TranslationResult.fromJson(e));
        } else if (e is Map) {
          parsedItems.add(
            TranslationResult.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }
    }

    final originalText = json['original_text']?.toString() ??
        (parsedItems.isNotEmpty ? parsedItems.first.originalText : '');
    final translation = json['translation']?.toString() ??
        (parsedItems.isNotEmpty ? parsedItems.first.translation : '');
    final price = json['price']?.toString() ??
        (parsedItems.isNotEmpty ? parsedItems.first.price : '');
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
      price: price,
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
        final list = <TranslationResult>[];
        for (final e in parsed) {
          if (e is Map<String, dynamic>) {
            list.add(TranslationResult.fromJson(e));
          } else if (e is Map) {
            list.add(
              TranslationResult.fromJson(Map<String, dynamic>.from(e)),
            );
          }
        }
        if (list.isNotEmpty) {
          final first = list.first;
          return TranslationResult(
            originalText: first.originalText,
            translation: first.translation,
            price: first.price,
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
      } else if (parsed is Map) {
        return TranslationResult.fromJson(Map<String, dynamic>.from(parsed));
      }

      throw Exception('Unexpected JSON structure');
    } catch (e) {
      // Fallback/Error parsing
      return TranslationResult(
        originalText: '텍스트를 파싱하는 데 실패했습니다.',
        translation: '해석할 수 없는 형식의 응답입니다.',
        price: '',
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
      'price': price,
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
