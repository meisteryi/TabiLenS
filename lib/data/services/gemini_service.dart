import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/translation_result.dart';
import '../models/detected_text_block.dart';
import '../../core/constants/env_keys.dart';

class GeminiService {
  final GenerativeModel _model;

  GeminiService() : _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: dotenv.env[EnvKeys.geminiApiKey] ?? '',
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );

  /// 1. Detect Japanese text blocks and their normalized 2D bounding boxes [ymin, xmin, ymax, xmax]
  Future<List<DetectedTextBlock>> detectTextBlocks(Uint8List imageBytes) async {
    final apiKey = dotenv.env[EnvKeys.geminiApiKey];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
      throw Exception('Gemini API key is not configured. Please set your key in the .env file.');
    }

    const prompt = '너는 OCR 분석기이자 이미지 객체 탐지기야. '
        '첨부된 이미지에서 보이는 모든 주요 일본어 텍스트 블록(세로쓰기, 간판, 손글씨, 메뉴 아이템 등)을 찾아줘. '
        '각 텍스트 블록의 정확한 원문 내용과 이미지 내 위치(bounding box)를 반드시 다음 JSON 배열 형식으로만 대답해줘.\n\n'
        '[\n'
        '  {\n'
        '    "text": "일본어 텍스트 내용",\n'
        '    "box_2d": [ymin, xmin, ymax, xmax]\n'
        '  }\n'
        ']\n\n'
        '※ 중요 규칙:\n'
        '1. box_2d의 ymin, xmin, ymax, xmax 좌표값은 이미지의 전체 크기 대비 0에서 1000 사이의 상대적 정수 값이어야 해. (예: ymin이 이미지 꼭대기 근처라면 20~50, ymax가 이미지 아래쪽이라면 800~950)\n'
        '2. 글씨 위치가 미세하게 잘리거나 밀리는 문제를 방지하기 위해, 각 일본어 텍스트 영역을 상하좌우로 10% 정도 넓게 충분히 감싸는 형태로 여유 있게 박스 영역(box_2d)을 설정해 줘.\n'
        '3. 마크다운 기호 없이 순수 JSON 배열만 반환해줘.';

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ]),
    ];

    return _retryOnRateLimit(() async {
      try {
        final response = await _model.generateContent(content);
        final rawText = response.text;
        if (rawText == null || rawText.isEmpty) {
          return [];
        }

        // Clean markdown block wrappers if present
        String cleanedJson = rawText.trim();
        if (cleanedJson.startsWith('```')) {
          cleanedJson = cleanedJson.replaceFirst(RegExp(r'^```(json)?'), '');
          if (cleanedJson.endsWith('```')) {
            cleanedJson = cleanedJson.substring(0, cleanedJson.length - 3);
          }
          cleanedJson = cleanedJson.trim();
        }

        final List<dynamic> parsed = json.decode(cleanedJson) as List<dynamic>;
        return parsed.map((e) => DetectedTextBlock.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        throw Exception('텍스트 영역 인식에 실패했습니다: $e');
      }
    });
  }

  /// 2. Perform deep translation and cultural analysis on only the selected text item
  Future<TranslationResult> analyzeSelectedText(
    Uint8List imageBytes,
    String selectedText,
  ) async {
    final apiKey = dotenv.env[EnvKeys.geminiApiKey];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
      throw Exception('Gemini API key is not configured. Please set your key in the .env file.');
    }

    final prompt = '너는 도쿄를 여행하는 한국인을 위한 현지 문화 가이드야. '
        '첨부된 이미지 전체 맥락과 특히 사용자가 선택한 일본어 텍스트 "$selectedText"를 상세 분석해줘. '
        '선택된 단어의 정확한 번역, 문화적 배경/해설, 주문 꿀팁, 그리고 해당 단어(메뉴)를 활용해서 현지 점원에게 말할 수 있는 완전한 일본어 주문용 예문 문장, 그리고 해당 음식이나 물건의 대표 이미지를 Unsplash 등 무료 이미지 사이트에서 검색하는 데 필요한 구체적인 단일 영어 키워드를 함께 구성해서 다음 JSON 형식으로만 답변해줘.\n\n'
        '{\n'
        '  "original_text": "$selectedText",\n'
        '  "translation": "사용자가 선택한 텍스트에 대한 어울리는 한국어 번역",\n'
        '  "context": "이 메뉴/단어의 유래, 역사, 상세한 음식 구성, 맛의 특징 등에 대한 문화적 해설",\n'
        '  "tip": "이 메뉴/매장에서 주문할 때 알아야 할 실전 꿀팁 또는 여행자용 유용한 정보",\n'
        '  "order_phrase_japanese": "해당 단어/메뉴를 활용해 일본어로 주문하거나 요청할 때 사용할 수 있는 완전한 일본어 문장 (예: [단어]를 하나 주세요, 혹은 [단어]를 빼주세요 등 상황에 맞는 유용한 일본어 문장)",\n'
        '  "order_phrase_pronunciation": "위의 order_phrase_japanese 문장의 자연스러운 한글 발음 표기 (예: "코레오 히토츠 쿠다사이")",\n'
        '  "order_phrase_translation": "위의 order_phrase_japanese 일본어 문장의 한국어 뜻 (예: "이것을 하나 주세요")",\n'
        '  "image_keyword": "해당 메뉴/대상을 가장 잘 대표하는 구체적인 1~2단어의 영어 검색 키워드. 만약 식음료 메뉴라면 이미지 검색 시 엉뚱한 비음식 사진이 나오는 것을 막기 위해 반드시 단어 뒤에 \x27 food\x27 또는 \x27 dish\x27 또는 \x27 beverage\x27 등을 함께 붙여서 생성해줘 (예: "ramen food", "sushi dish", "greentea beverage"). 무조건 영어로 기입할 것"\n'
        '}';

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ]),
    ];

    return _retryOnRateLimit(() async {
      try {
        final response = await _model.generateContent(content);
        final rawText = response.text;
        if (rawText == null || rawText.isEmpty) {
          throw Exception('Gemini API가 빈 응답을 반환했습니다.');
        }
        return TranslationResult.fromRawJson(rawText);
      } catch (e) {
        throw Exception('Gemini 상세 분석에 실패했습니다: $e');
      }
    });
  }

  /// Helper to retry an API call with exponential backoff on rate limits / overload errors
  Future<T> _retryOnRateLimit<T>(Future<T> Function() apiCall, {int maxRetries = 3}) async {
    int delaySeconds = 2;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await apiCall();
      } catch (e) {
        final errorStr = e.toString().toLowerCase();
        final isRateLimitOrOverload = errorStr.contains('429') ||
            errorStr.contains('quota exceeded') ||
            errorStr.contains('exhausted') ||
            errorStr.contains('overloaded') ||
            errorStr.contains('503') ||
            errorStr.contains('limit');

        if (isRateLimitOrOverload && attempt < maxRetries) {
          // Wait with exponential backoff
          await Future.delayed(Duration(seconds: delaySeconds));
          delaySeconds *= 2; // Increase delay (2s -> 4s -> 8s)
          continue;
        }
        rethrow;
      }
    }
    throw Exception('요청이 너무 많아 실패했습니다. 잠시 후 다시 시도해 주세요.');
  }
}
