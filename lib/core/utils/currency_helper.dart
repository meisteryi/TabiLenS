import 'package:intl/intl.dart';
import '../../providers/language_provider.dart';

class PriceInfo {
  final String originalPriceText;
  final double numericAmount;
  final int krwAmount;
  final String formattedKrw;

  const PriceInfo({
    required this.originalPriceText,
    required this.numericAmount,
    required this.krwAmount,
    required this.formattedKrw,
  });
}

class CurrencyHelper {
  // Approximate standard exchange rates to KRW (Korean Won)
  static const double rateJpy = 9.2; // 1 JPY = 9.2 KRW (100 JPY ≈ 920 KRW)
  static const double rateEur = 1480.0; // 1 EUR ≈ 1,480 KRW
  static const double rateUsd = 1350.0; // 1 USD ≈ 1,350 KRW
  static const double rateCny = 190.0; // 1 CNY ≈ 190 KRW
  static const double rateGbp = 1750.0; // 1 GBP ≈ 1,750 KRW

  /// Extracts price and calculates estimated KRW
  static PriceInfo? extractAndConvertPrice(
    String text, {
    LanguageMode? languageMode,
    String? explicitPrice,
  }) {
    // 1. If explicit price provided from Gemini
    if (explicitPrice != null && explicitPrice.trim().isNotEmpty) {
      final parsed = _parsePriceString(explicitPrice, languageMode);
      if (parsed != null) return parsed;
    }

    // 2. Otherwise attempt to extract from text
    return _parsePriceString(text, languageMode);
  }

  static PriceInfo? _parsePriceString(String raw, LanguageMode? lang) {
    if (raw.trim().isEmpty) return null;

    // A. Japanese Yen patterns: ¥1,200 or 1,200円 or 1200엔
    final jpyMatch = RegExp(r'(?:[¥￥]\s*([\d,]+)|([\d,]+)\s*(?:円|엔))').firstMatch(raw);
    if (jpyMatch != null) {
      final numStr = (jpyMatch.group(1) ?? jpyMatch.group(2) ?? '').replaceAll(',', '');
      final val = double.tryParse(numStr);
      if (val != null && val > 0) {
        return _buildPriceInfo(
          originalText: '${_formatNumber(val)}円',
          numeric: val,
          rate: rateJpy,
        );
      }
    }

    // B. Euro patterns: €14.50 or 14.50€ or 14,50 €
    final eurMatch = RegExp(r'(?:[€]\s*([\d,.]+)|([\d,.]+)\s*(?:€|유로))').firstMatch(raw);
    if (eurMatch != null) {
      final numStr = (eurMatch.group(1) ?? eurMatch.group(2) ?? '')
          .replaceAll(' ', '')
          .replaceAll(',', '.');
      final val = double.tryParse(numStr);
      if (val != null && val > 0) {
        return _buildPriceInfo(
          originalText: '€${_formatDecimal(val)}',
          numeric: val,
          rate: rateEur,
        );
      }
    }

    // C. USD patterns: $18.50 or 18.50$ or 18달러
    final usdMatch = RegExp(r'(?:[\$]\s*([\d,.]+)|([\d,.]+)\s*(?:\$|달러|USD))', caseSensitive: false).firstMatch(raw);
    if (usdMatch != null) {
      final numStr = (usdMatch.group(1) ?? usdMatch.group(2) ?? '').replaceAll(',', '');
      final val = double.tryParse(numStr);
      if (val != null && val > 0) {
        return _buildPriceInfo(
          originalText: '\$${_formatDecimal(val)}',
          numeric: val,
          rate: rateUsd,
        );
      }
    }

    // D. CNY patterns: 35元 or 35위안
    final cnyMatch = RegExp(r'(?:([\d,.]+)\s*(?:元|위안|块))').firstMatch(raw);
    if (cnyMatch != null) {
      final numStr = (cnyMatch.group(1) ?? '').replaceAll(',', '');
      final val = double.tryParse(numStr);
      if (val != null && val > 0) {
        return _buildPriceInfo(
          originalText: '${_formatDecimal(val)}元',
          numeric: val,
          rate: rateCny,
        );
      }
    }

    // E. GBP patterns: £10.00
    final gbpMatch = RegExp(r'(?:[£]\s*([\d,.]+)|([\d,.]+)\s*(?:£|파운드))').firstMatch(raw);
    if (gbpMatch != null) {
      final numStr = (gbpMatch.group(1) ?? gbpMatch.group(2) ?? '').replaceAll(',', '');
      final val = double.tryParse(numStr);
      if (val != null && val > 0) {
        return _buildPriceInfo(
          originalText: '£${_formatDecimal(val)}',
          numeric: val,
          rate: rateGbp,
        );
      }
    }

    // F. Fallback: If no explicit currency symbol found, deduce from language mode
    if (lang != null) {
      final plainMatch = RegExp(r'(?:^|[^\d])([\d]{1,3}(?:[,\s]\d{3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)(?:$|[^\d])').firstMatch(raw);
      if (plainMatch != null) {
        final numStr = (plainMatch.group(1) ?? '').replaceAll(',', '').replaceAll(' ', '');
        final val = double.tryParse(numStr);
        if (val != null && val > 0) {
          switch (lang) {
            case LanguageMode.japanese:
              // Usually Japanese dishes are 300 to 50000 yen
              if (val >= 100 && val <= 500000) {
                return _buildPriceInfo(
                  originalText: '${_formatNumber(val)}円',
                  numeric: val,
                  rate: rateJpy,
                );
              }
              break;
            case LanguageMode.french:
            case LanguageMode.spanish:
              if (val >= 1 && val <= 500) {
                return _buildPriceInfo(
                  originalText: '€${_formatDecimal(val)}',
                  numeric: val,
                  rate: rateEur,
                );
              }
              break;
            case LanguageMode.english:
              if (val >= 1 && val <= 500) {
                return _buildPriceInfo(
                  originalText: '\$${_formatDecimal(val)}',
                  numeric: val,
                  rate: rateUsd,
                );
              }
              break;
            case LanguageMode.chinese:
              if (val >= 1 && val <= 1000) {
                return _buildPriceInfo(
                  originalText: '${_formatDecimal(val)}元',
                  numeric: val,
                  rate: rateCny,
                );
              }
              break;
          }
        }
      }
    }

    return null;
  }

  static PriceInfo _buildPriceInfo({
    required String originalText,
    required double numeric,
    required double rate,
  }) {
    final rawKrw = (numeric * rate).round();
    // Round to nearest 100 won for readability if over 1000 won
    final roundedKrw = rawKrw >= 1000 ? ((rawKrw + 50) ~/ 100) * 100 : rawKrw;
    final formatter = NumberFormat('#,###');
    final formatted = '약 ${formatter.format(roundedKrw)}원';

    return PriceInfo(
      originalPriceText: originalText,
      numericAmount: numeric,
      krwAmount: roundedKrw,
      formattedKrw: formatted,
    );
  }

  static String _formatNumber(double val) {
    final formatter = NumberFormat('#,###');
    return formatter.format(val.round());
  }

  static String _formatDecimal(double val) {
    if (val == val.roundToDouble()) {
      return NumberFormat('#,###').format(val.round());
    }
    return NumberFormat('#,##0.00').format(val);
  }

  static String formatMultiplied(PriceInfo info, int quantity) {
    if (quantity <= 1) {
      return '${info.originalPriceText} (${info.formattedKrw})';
    }
    final totalKrw = info.krwAmount * quantity;
    final formatter = NumberFormat('#,###');
    return '${info.originalPriceText} × $quantity = 약 ${formatter.format(totalKrw)}원';
  }
}
