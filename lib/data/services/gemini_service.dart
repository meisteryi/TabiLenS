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
          model: 'gemini-2.5-flash-lite',
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
        '2. 마크다운 기호 없이 순수 JSON 배열만 반환해줘.';

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ]),
    ];

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
        '선택된 단어의 정확한 번역과 그것이 의미하는 문화적 배경, 식재료/설명, 주문 팁 등을 다음 JSON 형식으로만 답변해줘.\n\n'
        '{\n'
        '  "original_text": "$selectedText",\n'
        '  "translation": "사용자가 선택한 텍스트에 대한 어울리는 한국어 번역",\n'
        '  "context": "이 메뉴/단어의 유래, 역사, 상세한 음식 구성, 맛의 특징 등에 대한 문화적 해설",\n'
        '  "tip": "이 메뉴/매장에서 주문할 때 알아야 할 실전 꿀팁 또는 여행자용 유용한 정보"\n'
        '}';

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ]),
    ];

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
  }
}
