import 'dart:convert';
import 'dart:math' as math;
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
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.0,
      ),
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

    // Locate each visible text region independently; menu semantics must not
    // impose a regular grid or guessed line spacing on handwritten text.
    final fewShotSection = _buildDetectionFewShotForLanguage(sourceLanguage);

    final prompt =
        '''너는 메뉴판 이미지에서 글자의 2D 바운딩 박스를 검출하는 고정밀 Vision-OCR 시스템이야.
이미지에 적힌 모든 $sourceLanguage 메뉴 항목과 카테고리 제목을 정확하게 검출해줘.

【출력 형식: 순수 JSON 배열만 출력】
[
  {
    "text": "원문 글씨",
    "box_2d": [ymin, xmin, ymax, xmax]
  }
]
* 좌표는 0~1000 정규화 정수 [ymin, xmin, ymax, xmax].

【핵심 원칙: 글자마다 유동적인 박스 크기 (고정 규격/격자 복사 절대 금지!)】
모든 박스를 비슷한 높이로 일률적으로 찍어내면, 2줄 이상인 메뉴가 잘리고 아래로 갈수록 모든 박스가 밑으로 밀려 하단 그림이나 다른 메뉴 위로 침범하는 치명적인 문제가 발생해.
반드시 글자의 줄 수, 글자 크기, 실제 텍스트 영역에 맞추어 박스 높이와 너비를 글자마다 완전히 다르게 유동적으로 생성해!

$fewShotSection

【원칙 1: 2줄 이상의 메뉴는 반드시 윗줄과 아랫줄 전체를 감싸는 1개의 큰 박스로 통합】
- 메뉴명과 부가 설명 또는 가격이 2줄 이상인 경우 반드시 전체를 덮는 1개 박스로 생성해.
- 절대로 2줄 메뉴를 1줄 높이로 쪼개거나 좁게 만들지 마! 그러면 그 아래 모든 메뉴의 위치가 밀려버린다!

【원칙 2: 1행에 복수 메뉴가 있는 경우 분리 vs 단독 메뉴 단독 박스】
- 같은 행에 2개 이상의 메뉴가 가로로 나열되어 있으면 각각 독립된 좌/우 박스로 분리.
- 1개 메뉴만 있는 행은 해당 메뉴만 감싸고, 빈 여백 공간에는 절대로 빈 박스를 생성하지 마!

【원칙 3: 사진, 일러스트 그림, 장식 그래픽 박스 생성 절대 금지】
- 음식 사진, 일러스트 그림, 캐릭터, 장식 로고, 빈 배경에는 박스를 절대 만들지 마. 오직 실제 읽을 수 있는 텍스트에만 박스를 생성해!

설명이나 마크다운 없이 순수 JSON 배열만 출력해.''';

    final content = [
      Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
    ];

    try {
      return await _executeWithModelFallback((model) async {
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
        final rawBlocks = parsed
            .map((e) => DetectedTextBlock.fromJson(e as Map<String, dynamic>))
            .toList();
        return _filterAndDeduplicateBlocks(rawBlocks);
      }, onStatusChanged: onStatusChanged);
    } catch (e) {
      throw Exception('텍스트 영역 인식에 실패했습니다: $e');
    }
  }

  /// Post-process to remove empty boxes, micro-noise, and redundant nested fragments
  List<DetectedTextBlock> _filterAndDeduplicateBlocks(
    List<DetectedTextBlock> rawBlocks,
  ) {
    final valid = <DetectedTextBlock>[];
    for (final b in rawBlocks) {
      final text = b.text.trim();
      if (text.isEmpty || b.box2d.length < 4) continue;
      final ymin = b.box2d[0];
      final xmin = b.box2d[1];
      final ymax = b.box2d[2];
      final xmax = b.box2d[3];
      final h = ymax - ymin;
      final w = xmax - xmin;
      // Filter out collapsed or tiny noise fragments
      if (h <= 5 || w <= 5) continue;
      valid.add(b);
    }

    final filtered = <DetectedTextBlock>[];
    for (int i = 0; i < valid.length; i++) {
      final a = valid[i];
      final aBox = a.box2d;
      final aArea = (aBox[2] - aBox[0]) * (aBox[3] - aBox[1]);
      bool isSubsumed = false;

      for (int j = 0; j < valid.length; j++) {
        if (i == j) continue;
        final b = valid[j];
        final bBox = b.box2d;
        final bArea = (bBox[2] - bBox[0]) * (bBox[3] - bBox[1]);

        if (bArea <= aArea) continue;

        final interYmin = math.max(aBox[0], bBox[0]);
        final interXmin = math.max(aBox[1], bBox[1]);
        final interYmax = math.min(aBox[2], bBox[2]);
        final interXmax = math.min(aBox[3], bBox[3]);

        if (interYmax > interYmin && interXmax > interXmin) {
          final interArea = (interYmax - interYmin) * (interXmax - interXmin);
          // If 80%+ of a's area is inside b, a is a redundant sub-fragment
          if (aArea > 0 && (interArea / aArea) > 0.80) {
            isSubsumed = true;
            break;
          }
        }
      }

      if (!isSubsumed) {
        filtered.add(a);
      }
    }
    return filtered;
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

    final examples = _getOrderPhraseExamples(sourceLanguage, targetLanguage);
    final phraseExample = examples['phrase']!;
    final pronunciationExample = examples['pronunciation']!;
    final translationExample = examples['translation']!;

    final prompt =
        '너는 $sourceLanguage 메뉴판을 읽고 번역해 주는 현지 문화 및 음식 가이드야. 모든 응답 결과("translation", "context", "tip", "allergy_info", "order_phrase_pronunciation", "order_phrase_translation")는 반드시 사용자의 모국어인 **$targetLanguage**로 작성되어야 해.\n'
        '사용자가 $sourceLanguage 메뉴판에서 선택한 단어/메뉴 "$selectedText"를 상세 분석해줘. '
        '선택된 단어의 정확한 번역, 문화적 배경/해설, 주문 꿀팁, 알레르기 유발 가능 성분 정보, 그리고 해당 단어(메뉴)를 활용해서 현지 점원에게 말할 수 있는 완전한 $sourceLanguage 주문/요청용 예문 문장들을 다음 JSON 형식으로만 답변해줘.\n\n'
        '{\n'
        '  "original_text": "$selectedText",\n'
        '  "translation": "사용자가 선택한 텍스트에 대한 어울리는 $targetLanguage 번역",\n'
        '  "context": "이 메뉴/단어의 유래, 역사, 상세한 음식 구성, 맛의 특징 등에 대한 $targetLanguage 문화적 해설",\n'
        '  "tip": "이 메뉴/매장에서 주문할 때 알아야 할 실전 꿀팁 또는 여행자용 유용한 정보 ($targetLanguage로 작성)",\n'
        '  "allergy_info": "해당 음식에 포함될 가능성이 높은 주요 알레르기 유발 성분 (예: 대두, 밀가루, 계란, 유제품, 견과류, 갑각류 등) 및 주의사항 ($targetLanguage로 작성)",\n'
        '  "order_phrase": "해당 단어/메뉴를 활용해 현지어($sourceLanguage)로 주문하거나 요청할 때 사용할 수 있는 완전한 문장 (예: $phraseExample)",\n'
        '  "order_phrase_japanese": "위와 동일한 현지어($sourceLanguage) 주문 문장",\n'
        '  "order_phrase_pronunciation": "위의 현지어 문장을 $targetLanguage 사용자가 발음할 수 있게 표기 (예: $pronunciationExample)",\n'
        '  "order_phrase_translation": "위의 현지어 문장의 $targetLanguage 뜻 (예: $translationExample)"\n'
        '}';

    final content = [Content.text(prompt)];

    try {
      return await _executeWithModelFallback((model) async {
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
      }, onStatusChanged: onStatusChanged);
    } catch (e) {
      throw Exception('Gemini 상세 분석에 실패했습니다: $e');
    }
  }

  /// 3. OCR and Analyze a user-selected cropped image region directly
  Future<TranslationResult> analyzeCroppedImage(
    Uint8List cropBytes, {
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

    final examples = _getOrderPhraseExamples(sourceLanguage, targetLanguage);
    final phraseExample = examples['phrase']!;
    final pronunciationExample = examples['pronunciation']!;
    final translationExample = examples['translation']!;

    final prompt =
        '너는 $sourceLanguage 메뉴판을 읽고 번역해 주는 현지 음식 및 문화 가이드야. 모든 응답 결과("translation", "context", "tip", "allergy_info", "order_phrase_pronunciation", "order_phrase_translation")는 반드시 사용자의 모국어인 **$targetLanguage**로 작성되어야 해.\n'
        '첨부된 이미지는 사용자가 메뉴판에서 직접 손가락으로 드래그하여 지정한 영역이야.\n'
        '이 잘라낸 이미지 영역 안에는 1개 또는 2개 이상의 여러 메뉴 항목이 포함되어 있을 수 있어.\n\n'
        '【필수 지침】\n'
        '1. 이미지 영역 내에 보이는 **모든 메뉴 항목을 하나도 빠뜨리지 말고 각각 개별 항목으로 분리**하여 위에서 아래로(또는 읽는 순서대로) 모두 분석해줘!\n'
        '2. 메뉴가 1개만 있으면 1개 항목을, 여러 메뉴가 있으면 모든 메뉴를 items 배열에 담아 반환해.\n'
        '3. 2줄 이상으로 길게 적힌 메뉴명과 가격은 1개의 메뉴 항목으로 깔끔하게 통합해줘.\n'
        '4. 선택된 영역의 일부 메뉴만 자의적으로 고르거나 맨 아래 글자만 잡지 말고, 영역 안의 모든 텍스트를 누락 없이 빠짐없이 찾아내줘.\n\n'
        '【출력 JSON 형식: 반드시 아래 "items" 배열 구조로만 출력】\n'
        '{\n'
        '  "items": [\n'
        '    {\n'
        '      "original_text": "이미지에서 읽어낸 $sourceLanguage 원문 (요리명 및 가격 포함)",\n'
        '      "translation": "사용자 모국어($targetLanguage) 번역",\n'
        '      "context": "이 메뉴/단어의 유래, 역사, 상세한 음식 구성, 맛의 특징 등에 대한 $targetLanguage 문화적 해설",\n'
        '      "tip": "이 메뉴/매장에서 주문할 때 알아야 할 실전 꿀팁 또는 여행자용 유용한 정보 ($targetLanguage로 작성)",\n'
        '      "allergy_info": "해당 음식에 포함될 가능성이 높은 주요 알레르기 유발 성분 (예: 대두, 밀가루, 계란, 유제품, 견과류, 갑각류 등) 및 주의사항 ($targetLanguage로 작성)",\n'
        '      "order_phrase": "해당 메뉴를 활용해 현지어($sourceLanguage)로 주문하거나 요청할 때 사용할 수 있는 완전한 문장 (예: $phraseExample)",\n'
        '      "order_phrase_japanese": "위와 동일한 현지어($sourceLanguage) 주문 문장",\n'
        '      "order_phrase_pronunciation": "위의 현지어 문장을 $targetLanguage 사용자가 발음할 수 있게 표기 (예: $pronunciationExample)",\n'
        '      "order_phrase_translation": "위의 현지어 문장의 $targetLanguage 뜻 (예: $translationExample)",\n'
        '      "image_keyword": "이 요리의 대표적인 검색 키워드"\n'
        '    }\n'
        '  ]\n'
        '}';

    final content = [
      Content.multi([TextPart(prompt), DataPart('image/jpeg', cropBytes)]),
    ];

    try {
      return await _executeWithModelFallback((model) async {
        onStatusChanged?.call('AI가 선택한 영역의 글씨를 읽고 해설하는 중...');
        final response = await model.generateContent(content);
        onStatusChanged?.call('해설 완료: 메뉴 꿀팁 및 예문 정리 중...');
        final rawText = response.text;
        if (rawText == null || rawText.isEmpty) {
          throw Exception('Gemini API가 빈 응답을 반환했습니다.');
        }
        return TranslationResult.fromRawJson(rawText);
      }, onStatusChanged: onStatusChanged);
    } catch (e) {
      throw Exception('선택 영역 분석에 실패했습니다: $e');
    }
  }

  /// Build customized few-shot OCR bounding box examples tailored to the travel country language
  String _buildDetectionFewShotForLanguage(String sourceLanguage) {
    if (sourceLanguage == '영어') {
      return '''【Few-Shot 예시 - 높이와 너비의 다양성을 반드시 확인하라】
- 1줄 메뉴: {"text": "Cheeseburger \$12", "box_2d": [35, 435, 75, 580]}  <- height = 40 (1줄이므로 얇음)
- 1줄 메뉴: {"text": "French Fries \$6", "box_2d": [85, 435, 125, 580]}   <- height = 40 (1줄이므로 얇음)
- 2줄 메뉴: {"text": "Slow Smoked Pulled Pork Sandwich \$16", "box_2d": [130, 435, 195, 580]} <- height = 65 (2줄 전체 감싸서 큼!)
- 2줄 메뉴: {"text": "Crispy Buffalo Wings (10pcs) \$14", "box_2d": [200, 435, 255, 580]}   <- height = 55 (2줄 전체 감싸서 큼!)
- 1줄 메뉴: {"text": "Clam Chowder \$8", "box_2d": [260, 435, 295, 580]}   <- height = 35 (다시 1줄이므로 얇아짐!)
- 3줄 메뉴: {"text": "Chef's Special Grilled Salmon with Salad \$25", "box_2d": [490, 105, 605, 320]} <- height = 115 (3줄 전체 감싸서 큼!)
- 카테고리 제목: {"text": "APPETIZERS & SIDES", "box_2d": [50, 20, 95, 400]}''';
    } else if (sourceLanguage == '프랑스어') {
      return '''【Few-Shot 예시 - 높이와 너비의 다양성을 반드시 확인하라】
- 1줄 메뉴: {"text": "Soupe à l'oignon 8€", "box_2d": [35, 435, 75, 580]}  <- height = 40 (1줄이므로 얇음)
- 1줄 메뉴: {"text": "Croque Monsieur 9€", "box_2d": [85, 435, 125, 580]}   <- height = 40 (1줄이므로 얇음)
- 2줄 메뉴: {"text": "Magret de canard rôti au miel 24€", "box_2d": [130, 435, 195, 580]} <- height = 65 (2줄 전체 감싸서 큼!)
- 2줄 메뉴: {"text": "Entrecôte grillée avec frites maison 26€", "box_2d": [200, 435, 255, 580]}   <- height = 55 (2줄 전체 감싸서 큼!)
- 1줄 메뉴: {"text": "Crème brûlée 7€", "box_2d": [260, 435, 295, 580]}   <- height = 35 (다시 1줄이므로 얇아짐!)
- 3줄 메뉴: {"text": "Menu Gourmand Entrée + Plat + Dessert 32€", "box_2d": [490, 105, 605, 320]} <- height = 115 (3줄 전체 감싸서 큼!)
- 카테고리 제목: {"text": "PLATS PRINCIPAUX", "box_2d": [50, 20, 95, 400]}''';
    } else if (sourceLanguage == '스페인어') {
      return '''【Few-Shot 예시 - 높이와 너비의 다양성을 반드시 확인하라】
- 1줄 메뉴: {"text": "Tortilla española 6€", "box_2d": [35, 435, 75, 580]}  <- height = 40 (1줄이므로 얇음)
- 1줄 메뉴: {"text": "Patatas bravas 5€", "box_2d": [85, 435, 125, 580]}   <- height = 40 (1줄이므로 얇음)
- 2줄 메뉴: {"text": "Paella valenciana tradicional 18€", "box_2d": [130, 435, 195, 580]} <- height = 65 (2줄 전체 감싸서 큼!)
- 2줄 메뉴: {"text": "Gambas al ajillo con pan 14€", "box_2d": [200, 435, 255, 580]}   <- height = 55 (2줄 전체 감싸서 큼!)
- 1줄 메뉴: {"text": "Churros con chocolate 5€", "box_2d": [260, 435, 295, 580]}   <- height = 35 (다시 1줄이므로 얇아짐!)
- 3줄 메뉴: {"text": "Menú del Día con Postre y Bebida 15€", "box_2d": [490, 105, 605, 320]} <- height = 115 (3줄 전체 감싸서 큼!)
- 카테고리 제목: {"text": "TAPAS Y RACIONES", "box_2d": [50, 20, 95, 400]}''';
    } else if (sourceLanguage == '중국어') {
      return '''【Few-Shot 예시 - 높이와 너비의 다양성을 반드시 확인하라】
- 1줄 메뉴: {"text": "麻婆豆腐 32元", "box_2d": [35, 435, 75, 580]}  <- height = 40 (1줄이므로 얇음)
- 1줄 메뉴: {"text": "宫保鸡丁 38元", "box_2d": [85, 435, 125, 580]}   <- height = 40 (1줄이므로 얇음)
- 2줄 메뉴: {"text": "正宗川味麻辣水煮牛肉 58元", "box_2d": [130, 435, 195, 580]} <- height = 65 (2줄 전체 감싸서 큼!)
- 2줄 메뉴: {"text": "传统老北京挂炉烤鸭 88元", "box_2d": [200, 435, 255, 580]}   <- height = 55 (2줄 전체 감싸서 큼!)
- 1줄 메뉴: {"text": "鲜肉小笼汤包 25元", "box_2d": [260, 435, 295, 580]}   <- height = 35 (다시 1줄이므로 얇아짐!)
- 3줄 메뉴: {"text": "主厨特制滋补养生套餐 45元", "box_2d": [490, 105, 605, 320]} <- height = 115 (3줄 전체 감싸서 큼!)
- 카테고리 제목: {"text": "特色招牌菜", "box_2d": [50, 20, 95, 400]}''';
    } else {
      return '''【Few-Shot 예시 - 높이의 다양성을 반드시 확인하라】
- 1줄 메뉴: {"text": "チーズ揚 350", "box_2d": [35, 435, 75, 580]}  <- height = 40 (1줄이므로 얇음)
- 1줄 메뉴: {"text": "コロッケ 280", "box_2d": [85, 435, 125, 580]}   <- height = 40 (1줄이므로 얇음)
- 2줄 메뉴: {"text": "カニグラタンコロッケ 280", "box_2d": [130, 435, 195, 580]} <- height = 65 (2줄 전체 감싸서 1줄의 약 2배로 큼!)
- 2줄 메뉴: {"text": "フライドポテト 380", "box_2d": [200, 435, 255, 580]}   <- height = 55 (2줄 전체 감싸서 유동적으로 큼!)
- 1줄 메뉴: {"text": "ハムカツ 280", "box_2d": [260, 435, 295, 580]}   <- height = 35 (다시 1줄이므로 얇아짐!)
- 3줄 메뉴: {"text": "ネバネバ(温玉入り) 3種 380", "box_2d": [490, 105, 605, 320]} <- height = 115 (3줄 전체 감싸서 큼!)
- 세로 제목: {"text": "とりあえず", "box_2d": [50, 20, 470, 100]}     <- height = 420 (세로 전체)''';
    }
  }

  /// Get phrase examples matching the local destination language and the user's native language
  Map<String, String> _getOrderPhraseExamples(
    String sourceLanguage,
    String targetLanguage,
  ) {
    String phraseExample = '';
    String pronunciationExample = '';
    String translationExample = '';

    if (sourceLanguage == '영어') {
      phraseExample = 'Could I have one of this, please?';
      pronunciationExample = targetLanguage == '한국어'
          ? '쿠드 아이 해브 원 오브 디스, 플리즈?'
          : 'Could I have one of this, please?';
      translationExample = targetLanguage == '한국어'
          ? '이것 하나 주시겠어요?'
          : 'Could I have one of this, please?';
    } else if (sourceLanguage == '중국어') {
      phraseExample = '请给我这个。';
      pronunciationExample = targetLanguage == '한국어'
          ? '칭 게이 워 쩌거'
          : 'Qing gei wo zhe ge';
      translationExample = targetLanguage == '한국어'
          ? '이것을 주세요.'
          : 'Please give me this.';
    } else if (sourceLanguage == '스페인어') {
      phraseExample = '¿Me puede dar uno de este, por favor?';
      pronunciationExample = targetLanguage == '한국어'
          ? '메 푸에데 다르 우노 데 에스테, 포르 파보르?'
          : 'Me puede dar uno de este, por favor?';
      translationExample = targetLanguage == '한국어'
          ? '이것 하나 주시겠어요?'
          : 'Can you give me one of this, please?';
    } else if (sourceLanguage == '프랑스어') {
      phraseExample = 'Je voudrais celui-ci, s\'il vous plaît.';
      pronunciationExample = targetLanguage == '한국어'
          ? '쥬 부드헤 슬뤼-씨, 실 부 플레'
          : 'Je voudrais celui-ci, s\'il vous plait';
      translationExample = targetLanguage == '한국어'
          ? '이것 하나 주세요.'
          : 'I would like this one, please.';
    } else {
      phraseExample = 'これを一つください。';
      pronunciationExample = targetLanguage == '한국어'
          ? '코레오 히토츠 쿠다사이'
          : 'Kore o hitotsu kudasai';
      translationExample = targetLanguage == '한국어'
          ? '이것을 하나 주세요.'
          : 'Please give me one of this.';
    }

    return {
      'phrase': phraseExample,
      'pronunciation': pronunciationExample,
      'translation': translationExample,
    };
  }

  /// Helper to run API call with fallbacks for quota exceeded or model availability issues
  Future<T> _executeWithModelFallback<T>(
    Future<T> Function(GenerativeModel model) apiCall, {
    void Function(String status)? onStatusChanged,
  }) async {
    final models = [
      'gemini-3.1-flash-lite',
      'gemini-3.6-flash',
      'gemini-2.5-flash',
    ];

    // Priority order: start with the highest quota/speed model (gemini-3.1-flash-lite: 500 RPD) and fallback on quota or availability errors
    final prioritizedModels = List<String>.from(models);

    dynamic lastError;

    for (final modelName in prioritizedModels) {
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
          print(
            'Gemini 모델 $modelName 에러 발생 (시도 $attempt/$maxRetriesPerModel): $e',
          );

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
              errorStr.contains('unknown model') ||
              errorStr.contains('no longer available') ||
              errorStr.contains('deprecated') ||
              errorStr.contains('unsupported');

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
              onStatusChanged?.call(
                '$modelName 한도 초과: $delaySeconds초 대기 후 다시 시도합니다...',
              );
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
