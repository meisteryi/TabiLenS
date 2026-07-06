import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/translation_result.dart';
import '../models/detected_text_block.dart';
import '../../core/constants/env_keys.dart';

class GeminiService {
  // In-memory cache for detailed translations to avoid duplicate API calls
  final Map<String, TranslationResult> _translationCache = {};

  GeminiService();

  GenerativeModel _createModel(String modelName) {
    return GenerativeModel(
      model: modelName,
      apiKey: dotenv.env[EnvKeys.geminiApiKey] ?? '',
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
  }

  /// 1. Detect text blocks and their normalized 2D bounding boxes [ymin, xmin, ymax, xmax]
  Future<List<DetectedTextBlock>> detectTextBlocks(
    Uint8List imageBytes, {
    String sourceLanguage = '일본어',
    String targetLanguage = '한국어',
    void Function(String status)? onStatusChanged,
  }) async {
    final apiKey = dotenv.env[EnvKeys.geminiApiKey];
    if (apiKey == null ||
        apiKey.isEmpty ||
        apiKey == 'your_gemini_api_key_here') {
      throw Exception(
        'Gemini API key is not configured. Please set your key in the .env file.',
      );
    }

    final prompt =
        '너는 OCR 분석기이자 이미지 객체 탐지기 및 번역기야. '
        '첨부된 $sourceLanguage 메뉴판 이미지에서 보이는 모든 주요 $sourceLanguage 텍스트 블록(가로쓰기, 세로쓰기, 간판, 손글씨, 메뉴 아이템 등)을 찾아줘. '
        '각 텍스트 블록의 원문 내용, 이미지 내 위치(bounding box), 그리고 해당 단어의 간결한 $targetLanguage 번역 명칭(설명 없이 핵심 뜻만 짧게)을 반드시 다음 JSON 배열 형식으로만 대답해줘.\n\n'
        '[\n'
        '  {\n'
        '    "text": "$sourceLanguage 원문 텍스트 내용",\n'
        '    "box_2d": [ymin, xmin, ymax, xmax],\n'
        '    "translated_text": "간결한 $targetLanguage 번역 명칭"\n'
        '  }\n'
        ']\n\n'
        '※ 중요 규칙:\n'
        '1. box_2d의 ymin, xmin, ymax, xmax 좌표값은 이미지의 전체 크기 대비 0에서 1000 사이의 상대적 정수 값이어야 해. (예: ymin이 이미지 꼭대기 근처라면 20~50, ymax가 이미지 아래쪽이라면 800~950)\n'
        '2. 글씨 위치가 미세하게 잘리거나 밀리는 문제를 방지하기 위해, 각 $sourceLanguage 텍스트 영역을 상하좌우로 10% 정도 넓게 충분히 감싸는 형태로 여유 있게 박스 영역(box_2d)을 설정해 줘.\n'
        '3. translated_text는 긴 설명 없이 메뉴판에 표기하기 좋은 짧고 명확한 $targetLanguage 번역명만 적어야 해.\n'
        '4. 마크다운 기호 없이 순수 JSON 배열만 반환해줘.';

    final content = [
      Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
    ];

    try {
      return await _executeWithModelFallback(
        (model) async {
          onStatusChanged?.call('AI가 메뉴판에서 $sourceLanguage 단어를 탐지하는 중...');
          final response = await model.generateContent(content);
          onStatusChanged?.call('감지 완료: 텍스트 영역 정보 정리 및 매핑 중...');
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
          return parsed
              .map((e) => DetectedTextBlock.fromJson(e as Map<String, dynamic>))
              .toList();
        },
        onStatusChanged: onStatusChanged,
      );
    } catch (e) {
      throw Exception('텍스트 영역 인식에 실패했습니다: $e');
    }
  }

  /// 2. Perform deep translation and cultural analysis on only the selected text item (text-only for saving tokens)
  Future<TranslationResult> analyzeSelectedText(
    String selectedText, {
    String sourceLanguage = '일본어',
    String targetLanguage = '한국어',
    void Function(String status)? onStatusChanged,
  }) async {
    final cacheKey = '${sourceLanguage}_${targetLanguage}_$selectedText';
    if (_translationCache.containsKey(cacheKey)) {
      debugPrint('[GeminiService] 로컬 캐시에서 번역 정보 호출: $cacheKey');
      return _translationCache[cacheKey]!;
    }

    final apiKey = dotenv.env[EnvKeys.geminiApiKey];
    if (apiKey == null ||
        apiKey.isEmpty ||
        apiKey == 'your_gemini_api_key_here') {
      throw Exception(
        'Gemini API key is not configured. Please set your key in the .env file.',
      );
    }

    String phraseExample = '';
    String pronunciationExample = '';
    String translationExample = '';

    if (sourceLanguage == '영어') {
      phraseExample = 'One more, please.';
      pronunciationExample = targetLanguage == '한국어' ? '원 모어, 플리즈' : 'One more, please';
      translationExample = targetLanguage == '한국어' ? '하나 더 주세요.' : 'Give me one more.';
    } else if (sourceLanguage == '중국어') {
      phraseExample = '请给我这个。';
      pronunciationExample = targetLanguage == '한국어' ? '칭 게이 워 쩌거' : 'Qing gei wo zhe ge';
      translationExample = targetLanguage == '한국어' ? '이것을 주세요.' : 'Please give me this.';
    } else if (sourceLanguage == '스페인어') {
      phraseExample = 'Uno más, por favor.';
      pronunciationExample = targetLanguage == '한국어' ? '우노 마스, 포르 파보르' : 'Uno mas, por favor';
      translationExample = targetLanguage == '한국어' ? '하나 더 주세요.' : 'One more, please.';
    } else if (sourceLanguage == '프랑스어') {
      phraseExample = 'Un autre, s\'il vous plaît.';
      pronunciationExample = targetLanguage == '한국어' ? '앙 우트르, 실 부 플레' : 'Un autre, s\'il vous plait';
      translationExample = targetLanguage == '한국어' ? '하나 더 주세요.' : 'One more, please.';
    } else {
      phraseExample = 'これを一つください。';
      pronunciationExample = targetLanguage == '한국어' ? '코레오 히토츠 쿠다사이' : 'Kore o hitotsu kudasai';
      translationExample = targetLanguage == '한국어' ? '이것을 하나 주세요.' : 'Please give me one of this.';
    }

    final prompt =
        '너는 $sourceLanguage 메뉴판을 읽고 번역해 주는 현지 문화 및 음식 가이드야. 모든 응답 결과("translation", "context", "tip", "order_phrase_pronunciation", "order_phrase_translation")는 반드시 사용자의 모국어인 **$targetLanguage**로 작성되어야 해.\n'
        '사용자가 $sourceLanguage 메뉴판에서 선택한 단어/메뉴 "$selectedText"를 상세 분석해줘. '
        '선택된 단어의 정확한 번역, 문화적 배경/해설, 주문 꿀팁, 그리고 해당 단어(메뉴)를 활용해서 현지 점원에게 말할 수 있는 완전한 $sourceLanguage 주문/요청용 예문 문장들을 다음 JSON 형식으로만 답변해줘.\n\n'
        '{\n'
        '  "original_text": "$selectedText",\n'
        '  "translation": "사용자가 선택한 텍스트에 대한 어울리는 $targetLanguage 번역",\n'
        '  "context": "이 메뉴/단어의 유래, 역사, 상세한 음식 구성, 맛의 특징 등에 대한 $targetLanguage 문화적 해설",\n'
        '  "tip": "이 메뉴/매장에서 주문할 때 알아야 할 실전 꿀팁 또는 여행자용 유용한 정보 ($targetLanguage로 작성)",\n'
        '  "order_phrase_japanese": "해당 단어/메뉴를 활용해 현지어($sourceLanguage)로 주문하거나 요청할 때 사용할 수 있는 완전한 문장 (예: $phraseExample)",\n'
        '  "order_phrase_pronunciation": "위의 현지어 문장을 $targetLanguage 사용자가 발음할 수 있게 한글 표기 또는 알파벳/병음 등으로 적어주기 (예: $pronunciationExample)",\n'
        '  "order_phrase_translation": "위의 현지어 문장의 $targetLanguage 뜻 (예: $translationExample)"\n'
        '}';

    final content = [Content.text(prompt)];

    try {
      return await _executeWithModelFallback(
        (model) async {
          onStatusChanged?.call('AI가 메뉴 상세 의미 및 문화적 해설 분석 중...');
          final response = await model.generateContent(content);
          onStatusChanged?.call('해설 완료: 메뉴 꿀팁 및 예문 정리 중...');
          final rawText = response.text;
          if (rawText == null || rawText.isEmpty) {
            throw Exception('Gemini API가 빈 응답을 반환했습니다.');
          }
          final result = TranslationResult.fromRawJson(rawText);
          _translationCache[cacheKey] = result;
          return result;
        },
        onStatusChanged: onStatusChanged,
      );
    } catch (e) {
      throw Exception('Gemini 상세 분석에 실패했습니다: $e');
    }
  }

  /// Helper to run API call with fallbacks for quota exceeded or model availability issues
  Future<T> _executeWithModelFallback<T>(
    Future<T> Function(GenerativeModel model) apiCall, {
    void Function(String status)? onStatusChanged,
  }) async {
    final models = [
      'gemini-2.5-flash',
      'gemini-2.5-flash-lite',
      'gemini-2.0-flash',
      'gemini-2.0-flash-lite',
      'gemini-3.5-flash',
      'gemini-3.1-flash-lite',
    ];

    // Shuffle the list of models to randomize the starting model and distribute quota load
    final shuffledModels = List<String>.from(models)..shuffle();

    dynamic lastError;

    for (final modelName in shuffledModels) {
      final model = _createModel(modelName);
      int delaySeconds = 1;
      const int maxRetriesPerModel = 2;

      for (int attempt = 1; attempt <= maxRetriesPerModel; attempt++) {
        try {
          onStatusChanged?.call('AI 모델($modelName)에 연결하는 중...');
          return await apiCall(model);
        } catch (e) {
          lastError = e;
          final errorStr = e.toString().toLowerCase();

          // ignore: avoid_print
          print('Gemini 모델 $modelName 에러 발생 (시도 $attempt/$maxRetriesPerModel): $e');

          final isRateLimitOrOverload =
              errorStr.contains('429') ||
              errorStr.contains('quota exceeded') ||
              errorStr.contains('exhausted') ||
              errorStr.contains('overloaded') ||
              errorStr.contains('503') ||
              errorStr.contains('limit');

          final isModelNotFoundError =
              errorStr.contains('not found') ||
              errorStr.contains('404') ||
              errorStr.contains('invalid model') ||
              errorStr.contains('unknown model');

          if (isModelNotFoundError) {
            // ignore: avoid_print
            print('$modelName 모델이 지원되지 않거나 찾을 수 없어 다음 모델로 넘어갑니다.');
            onStatusChanged?.call('$modelName 지원 불가: 다음 모델로 전환합니다.');
            break;
          }

          if (isRateLimitOrOverload) {
            if (attempt < maxRetriesPerModel) {
              // ignore: avoid_print
              print('$modelName 호출 한도 초과/과부하로 인해 $delaySeconds초 대기 후 재시도합니다.');
              onStatusChanged?.call('$modelName 한도 초과: $delaySeconds초 대기 후 다시 시도합니다...');
              await Future.delayed(Duration(seconds: delaySeconds));
              delaySeconds *= 2;
              continue;
            } else {
              // ignore: avoid_print
              print('$modelName 최대 시도 횟수 초과로 인해 다음 모델로 넘어갑니다.');
              onStatusChanged?.call('$modelName 한도 초과: 다른 대체 AI 모델로 전환하는 중...');
              break;
            }
          }
          rethrow; // For other errors (JSON parse, etc.), rethrow immediately
        }
      }
    }
    throw lastError ?? Exception('모든 Gemini 모델의 호출 한도를 초과했습니다.');
  }
}
