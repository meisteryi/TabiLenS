import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../data/models/detected_text_block.dart';
import 'gemini_provider.dart';
import 'language_provider.dart';
import 'detection_mode_provider.dart';

class TextSelectionState {
  final AsyncValue<List<DetectedTextBlock>> blocks;
  final List<DetectedTextBlock> selectedBlocks;
  final String loadingStatus;

  TextSelectionState({
    required this.blocks,
    required this.selectedBlocks,
    this.loadingStatus = '',
  });

  TextSelectionState copyWith({
    AsyncValue<List<DetectedTextBlock>>? blocks,
    List<DetectedTextBlock>? selectedBlocks,
    String? loadingStatus,
  }) {
    return TextSelectionState(
      blocks: blocks ?? this.blocks,
      selectedBlocks: selectedBlocks ?? this.selectedBlocks,
      loadingStatus: loadingStatus ?? this.loadingStatus,
    );
  }

  /// Combine all selected text blocks sorted by standard reading order
  String get combinedSelectedText {
    if (selectedBlocks.isEmpty) return '';

    // Create a copy and sort by y coordinate (rows) first, then x coordinate (columns)
    final sorted = List<DetectedTextBlock>.from(selectedBlocks)
      ..sort((a, b) {
        // If they are roughly on the same vertical line/row (diff in y is small), sort left-to-right
        const int rowThreshold = 40; // coordinates are normalized 0-1000
        final int yDiff = (a.box2d[0] - b.box2d[0]).abs();
        if (yDiff < rowThreshold) {
          return a.box2d[1].compareTo(b.box2d[1]);
        }
        // Otherwise, sort top-to-bottom
        return a.box2d[0].compareTo(b.box2d[0]);
      });

    return sorted.map((e) => e.text).join(' ');
  }
}

class TextSelectionNotifier extends Notifier<TextSelectionState> {
  @override
  TextSelectionState build() {
    return TextSelectionState(
      blocks: const AsyncData([]),
      selectedBlocks: [],
      loadingStatus: '',
    );
  }

  Future<void> detectBlocks(XFile image) async {
    final mode = ref.read(detectionModeProvider);
    final activeLang = ref.read(languageProvider);

    state = state.copyWith(
      blocks: const AsyncLoading(),
      selectedBlocks: [],
      loadingStatus: mode == DetectionMode.onDevice
          ? '기기 내부 모델로 텍스트를 분석하고 있습니다...'
          : '메뉴판 이미지 파일을 읽고 있습니다...',
    );

    final blocksState = await AsyncValue.guard(() async {
      if (mode == DetectionMode.onDevice) {
        return await _detectOnDevice(image, activeLang);
      } else {
        final geminiService = ref.read(geminiServiceProvider);
        final bytes = await image.readAsBytes();
        return await geminiService.detectTextBlocks(
          bytes,
          sourceLanguage: activeLang.name,
          onStatusChanged: (status) {
            state = state.copyWith(loadingStatus: status);
          },
        );
      }
    });

    state = state.copyWith(blocks: blocksState, loadingStatus: '');
  }

  Future<List<DetectedTextBlock>> _detectOnDevice(
    XFile image,
    LanguageMode activeLang,
  ) async {
    // 1. Get image dimensions
    final bytes = await image.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frameInfo = await codec.getNextFrame();
    final imageWidth = frameInfo.image.width;
    final imageHeight = frameInfo.image.height;

    // 2. Select ML Kit Script based on language
    TextRecognitionScript script;
    switch (activeLang) {
      case LanguageMode.japanese:
        script = TextRecognitionScript.japanese;
        break;
      case LanguageMode.chinese:
        script = TextRecognitionScript.chinese;
        break;
      default:
        script = TextRecognitionScript.latin;
    }

    final textRecognizer = TextRecognizer(script: script);
    final inputImage = InputImage.fromFilePath(image.path);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    final List<DetectedTextBlock> detectedBlocks = [];

    // Map RecognizedText lines or blocks to DetectedTextBlock
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final rect = line.boundingBox;

        // Normalize coordinates to 0-1000 range
        final ymin = ((rect.top / imageHeight) * 1000).round().clamp(0, 1000);
        final xmin = ((rect.left / imageWidth) * 1000).round().clamp(0, 1000);
        final ymax = ((rect.bottom / imageHeight) * 1000).round().clamp(0, 1000);
        final xmax = ((rect.right / imageWidth) * 1000).round().clamp(0, 1000);

        detectedBlocks.add(
          DetectedTextBlock(
            text: line.text,
            box2d: [ymin, xmin, ymax, xmax],
          ),
        );
      }
    }

    return detectedBlocks;
  }

  void selectBlock(DetectedTextBlock block) {
    final list = List<DetectedTextBlock>.from(state.selectedBlocks);
    if (list.contains(block)) {
      list.remove(block);
    } else {
      list.add(block);
    }
    state = state.copyWith(selectedBlocks: list);
  }

  void clear() {
    state = TextSelectionState(
      blocks: const AsyncData([]),
      selectedBlocks: [],
      loadingStatus: '',
    );
  }
}

final textSelectionProvider =
    NotifierProvider<TextSelectionNotifier, TextSelectionState>(() {
  return TextSelectionNotifier();
});
