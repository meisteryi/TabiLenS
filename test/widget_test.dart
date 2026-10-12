import 'package:flutter_test/flutter_test.dart';
import 'package:detect_and_explain/data/models/translation_result.dart';
import 'package:detect_and_explain/core/utils/currency_helper.dart';
import 'package:detect_and_explain/providers/language_provider.dart';

void main() {
  group('TranslationResult Model Tests', () {
    test('handles missing or null fields gracefully without throwing', () {
      final json = <String, dynamic>{
        'original_text': '牛丼',
        'translation': '소고기 덮밥',
        // price and others missing/null
      };

      final result = TranslationResult.fromJson(json);

      expect(result.originalText, equals('牛丼'));
      expect(result.translation, equals('소고기 덮밥'));
      expect(result.price, equals(''));
      expect(result.allergyInfo, equals(''));
      expect(result.allItems.length, equals(1));
    });

    test('parses multi-item response correctly', () {
      const rawJson = '''
      {
        "items": [
          {
            "original_text": "ラーメン 850円",
            "translation": "라멘",
            "price": "850円"
          },
          {
            "original_text": "餃子 400円",
            "translation": "만두",
            "price": "400円"
          }
        ]
      }
      ''';

      final result = TranslationResult.fromRawJson(rawJson);

      expect(result.allItems.length, equals(2));
      expect(result.allItems[0].originalText, equals('ラーメン 850円'));
      expect(result.allItems[0].price, equals('850円'));
      expect(result.allItems[1].price, equals('400円'));
    });
  });

  group('CurrencyHelper Tests', () {
    test('detects Japanese Yen correctly and converts to KRW', () {
      final info = CurrencyHelper.extractAndConvertPrice(
        '牛丼 1,200円',
        languageMode: LanguageMode.japanese,
      );

      expect(info, isNotNull);
      expect(info!.originalPriceText, equals('1,200円'));
      expect(info.numericAmount, equals(1200.0));
      expect(info.krwAmount, greaterThan(10000));
    });

    test('multiplies price and formats correctly for order card', () {
      final info = CurrencyHelper.extractAndConvertPrice(
        '1000円',
        languageMode: LanguageMode.japanese,
      );

      expect(info, isNotNull);
      final single = CurrencyHelper.formatMultiplied(info!, 1);
      final doubleQty = CurrencyHelper.formatMultiplied(info, 2);

      expect(single, contains('1,000円'));
      expect(doubleQty, contains('1,000円 × 2'));
    });
  });
}
