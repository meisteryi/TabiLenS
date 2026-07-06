import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/image_provider.dart';
import '../providers/text_selection_provider.dart';
import '../providers/gemini_provider.dart';
import 'package:flutter/foundation.dart';
import '../providers/language_provider.dart';
import 'result_screen.dart';

class TextSelectionScreen extends ConsumerStatefulWidget {
  const TextSelectionScreen({super.key});

  @override
  ConsumerState<TextSelectionScreen> createState() =>
      _TextSelectionScreenState();
}

class _TextSelectionScreenState extends ConsumerState<TextSelectionScreen> {
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  void _loadImageSize() {
    final imageFile = ref.read(imageProvider);
    if (imageFile == null) return;

    final ImageProvider provider = kIsWeb
        ? NetworkImage(imageFile.path)
        : FileImage(File(imageFile.path));

    final ImageStream stream = provider.resolve(const ImageConfiguration());

    stream.addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        if (mounted) {
          setState(() {
            _imageSize = Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            );
          });
        }
      }),
    );
  }

  void _handleTranslation(BuildContext context, String text) {
    final image = ref.read(imageProvider);
    if (image != null) {
      ref
          .read(geminiNotifierProvider.notifier)
          .translateSelectedBlock(image, text);
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const ResultScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageFile = ref.watch(imageProvider);
    final selectionState = ref.watch(textSelectionProvider);
    final activeLang = ref.watch(languageProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (imageFile == null) {
      return const Scaffold(body: Center(child: Text('선택된 사진이 없습니다.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('텍스트 선택'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            ref.read(textSelectionProvider.notifier).clear();
            ref.read(imageProvider.notifier).clear();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: selectionState.blocks.when(
        loading: () => _BuildDetectionLoadingState(imagePath: imageFile.path),
        error: (error, stack) => _BuildErrorState(
          errorMessage: error.toString(),
          onRetry: () =>
              ref.read(textSelectionProvider.notifier).detectBlocks(imageFile),
        ),
        data: (blocks) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                color: colorScheme.primary.withValues(alpha: 0.05),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '사진 속 번역을 원하는 ${activeLang.name} 박스를 터치해 선택하세요.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Interactive Image Canvas
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _imageSize == null
                        ? const CircularProgressIndicator()
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              // Calculate rendered size maintaining aspect ratio
                              final double scaleX =
                                  constraints.maxWidth / _imageSize!.width;
                              final double scaleY =
                                  constraints.maxHeight / _imageSize!.height;
                              final double scale = scaleX < scaleY
                                  ? scaleX
                                  : scaleY;

                              final renderedWidth = _imageSize!.width * scale;
                              final renderedHeight = _imageSize!.height * scale;

                              return Container(
                                width: renderedWidth,
                                height: renderedHeight,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: InteractiveViewer(
                                    maxScale: 5.0,
                                    child: Stack(
                                      children: [
                                        // The Image itself
                                        Positioned.fill(
                                          child: kIsWeb
                                              ? Image.network(
                                                  imageFile.path,
                                                  fit: BoxFit.fill,
                                                )
                                              : Image.file(
                                                  File(imageFile.path),
                                                  fit: BoxFit.fill,
                                                ),
                                        ),
  
                                        // Clickable boxes
                                        ...blocks.map((block) {
                                          // box2d: [ymin, xmin, ymax, xmax] (0 to 1000)
                                          final double ymin =
                                              block.box2d[0] *
                                              renderedHeight /
                                              1000;
                                          final double xmin =
                                              block.box2d[1] *
                                              renderedWidth /
                                              1000;
                                          final double ymax =
                                              block.box2d[2] *
                                              renderedHeight /
                                              1000;
                                          final double xmax =
                                              block.box2d[3] *
                                              renderedWidth /
                                              1000;
  
                                          // Add a small rendering margin to prevent tight cropping or slight coordinate shifts
                                          final double boxWidth = xmax - xmin;
                                          final double boxHeight = ymax - ymin;
                                          final double paddingX =
                                              boxWidth * 0.05; // 5% padding
                                          final double paddingY =
                                              boxHeight * 0.05; // 5% padding
                                          final double left = (xmin - paddingX)
                                              .clamp(0.0, renderedWidth);
                                          final double top = (ymin - paddingY)
                                              .clamp(0.0, renderedHeight);
                                          final double maxWidth =
                                              (renderedWidth - left).clamp(
                                                0.0,
                                                renderedWidth,
                                              );
                                          final double maxHeight =
                                              (renderedHeight - top).clamp(
                                                0.0,
                                                renderedHeight,
                                              );
                                          final double width =
                                              (boxWidth + (paddingX * 2)).clamp(
                                                0.0,
                                                maxWidth,
                                              );
                                          final double height =
                                              (boxHeight + (paddingY * 2)).clamp(
                                                0.0,
                                                maxHeight,
                                              );
  
                                          final isSelected = selectionState
                                              .selectedBlocks
                                              .contains(block);
  
                                          return Positioned(
                                            left: left,
                                            top: top,
                                            width: width,
                                            height: height,
                                            child: GestureDetector(
                                              onTap: () {
                                                ref
                                                    .read(
                                                      textSelectionProvider
                                                          .notifier,
                                                    )
                                                    .selectBlock(block);
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 150,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? colorScheme.primary
                                                            .withValues(
                                                              alpha: 0.25,
                                                            )
                                                      : Colors.black.withValues(
                                                          alpha: 0.15,
                                                        ),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? colorScheme.primary
                                                        : Colors.amber.withValues(
                                                            alpha: 0.6,
                                                          ),
                                                    width: isSelected ? 2.5 : 1.5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: block.translatedText != null &&
                                                        block.translatedText!.isNotEmpty
                                                    ? Center(
                                                        child: Padding(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 2.0,
                                                          ),
                                                          child: FittedBox(
                                                            fit: BoxFit.scaleDown,
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(
                                                                horizontal: 4,
                                                                vertical: 2,
                                                              ),
                                                              decoration: BoxDecoration(
                                                                color: (isSelected
                                                                        ? colorScheme.primary
                                                                        : Colors.black)
                                                                    .withValues(
                                                                  alpha: 0.65,
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius.circular(4),
                                                              ),
                                                              child: Text(
                                                                block.translatedText!,
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    : null,
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),

              // Bottom Action Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (selectionState.selectedBlocks.isNotEmpty) ...[
                        Text(
                          '선택된 텍스트',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          selectionState.combinedSelectedText,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => _handleTranslation(
                            context,
                            selectionState.combinedSelectedText,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            '선택한 텍스트 해설 및 가이드 보기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.05,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(16),
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.02,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${activeLang.name} 박스를 선택해 주세요.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BuildDetectionLoadingState extends ConsumerWidget {
  final String? imagePath;

  const _BuildDetectionLoadingState({this.imagePath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeLang = ref.watch(languageProvider);
    final selectionState = ref.watch(textSelectionProvider);

    String statusTitle = '${activeLang.name} 텍스트 감지 중...';
    String statusDesc = selectionState.loadingStatus.isNotEmpty
        ? selectionState.loadingStatus
        : 'AI가 사진 속 글씨 영역들을 찾고 있습니다.\n잠시만 기다려 주세요.';

    return Stack(
      fit: StackFit.expand,
      children: [
        if (imagePath != null)
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: kIsWeb
                  ? Image.network(imagePath!, fit: BoxFit.cover)
                  : Image.file(File(imagePath!), fit: BoxFit.cover),
            ),
          ),
        Container(color: colorScheme.surface.withValues(alpha: 0.85)),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                statusTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                statusDesc,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BuildErrorState extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const _BuildErrorState({required this.errorMessage, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cleanMessage = errorMessage.replaceAll('Exception:', '').trim();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 20),
            Text(
              '텍스트 인식 오류',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cleanMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
