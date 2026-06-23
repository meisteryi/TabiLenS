import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/detected_text_block.dart';
import 'gemini_provider.dart';

class TextSelectionState {
  final AsyncValue<List<DetectedTextBlock>> blocks;
  final List<DetectedTextBlock> selectedBlocks;

  TextSelectionState({
    required this.blocks,
    required this.selectedBlocks,
  });

  TextSelectionState copyWith({
    AsyncValue<List<DetectedTextBlock>>? blocks,
    List<DetectedTextBlock>? selectedBlocks,
  }) {
    return TextSelectionState(
      blocks: blocks ?? this.blocks,
      selectedBlocks: selectedBlocks ?? this.selectedBlocks,
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
    );
  }

  Future<void> detectBlocks(XFile image) async {
    state = state.copyWith(blocks: const AsyncLoading(), selectedBlocks: []);

    final geminiService = ref.read(geminiServiceProvider);
    
    final blocksState = await AsyncValue.guard(() async {
      final bytes = await image.readAsBytes();
      return await geminiService.detectTextBlocks(bytes);
    });

    state = state.copyWith(blocks: blocksState);
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
    );
  }
}

final textSelectionProvider = NotifierProvider<TextSelectionNotifier, TextSelectionState>(() {
  return TextSelectionNotifier();
});
