import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/image_provider.dart';
import '../providers/gemini_provider.dart';
import '../providers/text_selection_provider.dart';
import '../data/services/tts_service.dart';
import '../providers/favorites_provider.dart';
import '../data/models/translation_result.dart';
import 'package:flutter/foundation.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedImage = ref.watch(imageProvider);
    final geminiState = ref.watch(geminiNotifierProvider);
    final isTtsSpeaking = ref.watch(ttsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('분석 결과'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            ref.read(geminiNotifierProvider.notifier).reset();
            ref.read(textSelectionProvider.notifier).clear();
            ref.read(imageProvider.notifier).clear();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        actions: [
          geminiState.maybeWhen(
            data: (result) {
              if (result == null) return const SizedBox.shrink();
              final isBookmarked = ref.watch(favoritesProvider).any(
                    (folder) => folder.items.any(
                      (item) => item.result.originalText == result.originalText,
                    ),
                  );

              return IconButton(
                icon: Icon(
                  isBookmarked ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isBookmarked ? Colors.amber : null,
                  size: 28,
                ),
                onPressed: () {
                  _showFavoritesBottomSheet(
                    context,
                    ref,
                    result,
                    selectedImage?.path ?? '',
                  );
                },
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: geminiState.when(
        loading: () => _BuildLoadingState(imagePath: selectedImage?.path),
        error: (error, stack) => _BuildErrorState(
          errorMessage: error.toString(),
          onRetry: () {
            final combinedText = ref
                .read(textSelectionProvider)
                .combinedSelectedText;
            if (selectedImage != null && combinedText.isNotEmpty) {
              ref
                  .read(geminiNotifierProvider.notifier)
                  .translateSelectedBlock(selectedImage, combinedText);
            }
          },
        ),
        data: (result) {
          if (result == null) {
            return _BuildLoadingState(imagePath: selectedImage?.path);
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Display input image
                if (selectedImage != null)
                  Builder(
                    builder: (context) {
                      final imageFileExists = kIsWeb || File(selectedImage.path).existsSync();
                      if (!imageFileExists) {
                        return Container(
                          height: 180,
                          width: double.infinity,
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.onSurface.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colorScheme.onSurface.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported_rounded,
                                size: 40,
                                color: colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '이미지를 표시할 수 없습니다',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '원본 사진 파일이 삭제되었거나 존재하지 않습니다.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Container(
                        height: 220,
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: kIsWeb
                              ? Image.network(
                                  selectedImage.path,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: colorScheme.onSurface.withValues(alpha: 0.05),
                                    child: Icon(
                                      Icons.broken_image_rounded,
                                      size: 40,
                                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                                    ),
                                  ),
                                )
                              : Image.file(
                                  File(selectedImage.path),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: colorScheme.onSurface.withValues(alpha: 0.05),
                                    child: Icon(
                                      Icons.broken_image_rounded,
                                      size: 40,
                                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                                    ),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      // 1. Original Text Card
                      _BuildResultCard(
                        title: '인식된 일본어 원문',
                        icon: Icons.language_rounded,
                        iconColor: colorScheme.secondary,
                        content: result.originalText,
                        contentStyle: theme.textTheme.bodyLarge?.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                        action: IconButton(
                          icon: Icon(
                            isTtsSpeaking
                                ? Icons.stop_circle_rounded
                                : Icons.volume_up_rounded,
                            color: colorScheme.primary,
                          ),
                          onPressed: () {
                            final ttsNotifier = ref.read(ttsProvider.notifier);
                            if (isTtsSpeaking) {
                              ttsNotifier.stop();
                            } else {
                              ttsNotifier.speak(result.originalText);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Translation Card
                      _BuildResultCard(
                        title: '한국어 번역',
                        icon: Icons.translate_rounded,
                        iconColor: colorScheme.primary,
                        content: result.translation,
                        contentStyle: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. Cultural Context Card
                      _BuildResultCard(
                        title: '문화적 해설',
                        icon: Icons.auto_awesome_rounded,
                        iconColor: Colors.amber.shade700,
                        content: result.context,
                        contentStyle: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),



                      // 3.5. Order Phrase Card
                      if (result.orderPhraseJapanese.isNotEmpty) ...[
                        _BuildResultCard(
                          title: '현지 주문 예문',
                          icon: Icons.chat_bubble_outline_rounded,
                          iconColor: Colors.deepPurple,
                          action: IconButton(
                            icon: Icon(
                              isTtsSpeaking
                                  ? Icons.stop_circle_rounded
                                  : Icons.volume_up_rounded,
                              color: Colors.deepPurple,
                            ),
                            onPressed: () {
                              final ttsNotifier = ref.read(
                                ttsProvider.notifier,
                              );
                              if (isTtsSpeaking) {
                                ttsNotifier.stop();
                              } else {
                                ttsNotifier.speak(result.orderPhraseJapanese);
                              }
                            },
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result.orderPhraseJapanese,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '[발음] ${result.orderPhrasePronunciation}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '뜻: ${result.orderPhraseTranslation}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 4. Practical Tip Card
                      _BuildResultCard(
                        title: '현지 이용 꿀팁',
                        icon: Icons.lightbulb_rounded,
                        iconColor: Colors.teal,
                        content: result.tip,
                        contentStyle: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BuildResultCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String content;
  final TextStyle? contentStyle;
  final Widget? action;
  final Widget? child;

  const _BuildResultCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    this.content = '',
    this.contentStyle,
    this.action,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 14),
          child ??
              Text(content, style: contentStyle ?? theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _BuildLoadingState extends StatelessWidget {
  final String? imagePath;

  const _BuildLoadingState({this.imagePath});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (imagePath != null && (kIsWeb || File(imagePath!).existsSync()))
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: kIsWeb
                  ? Image.network(
                      imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    )
                  : Image.file(
                      File(imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
            ),
          ),
        Container(color: colorScheme.surface.withValues(alpha: 0.85)),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Gemini AI 분석 중...',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '세로쓰기와 손글씨를 판독하고 있습니다.\n잠시만 기다려 주세요.',
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

    // Clean up generic exception prefixes
    final cleanMessage = errorMessage.replaceAll('Exception:', '').trim();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 72,
              color: colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              '분석 중 오류 발생',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              cleanMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),
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

// Representative menu item photo card using Unsplash keywords


// Favorites management bottom sheet modal
void _showFavoritesBottomSheet(
  BuildContext context,
  WidgetRef ref,
  TranslationResult result,
  String imagePath,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final folders = ref.watch(favoritesProvider);
          final favoritesNotifier = ref.read(favoritesProvider.notifier);
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              top: 24,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '즐겨찾기 폴더 선택',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: folders.length,
                    itemBuilder: (context, index) {
                      final folder = folders[index];
                      final isInFolder = favoritesNotifier.isItemInFolder(folder.id, result.originalText);

                      return ListTile(
                        leading: Text(
                          folder.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(folder.name),
                        trailing: Icon(
                          isInFolder ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: isInFolder ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                        onTap: () {
                          ref.read(favoritesProvider.notifier).toggleFavorite(folder.id, imagePath, result);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _showCreateFolderDialog(context, ref);
                  },
                  icon: const Icon(Icons.create_new_folder_outlined),
                  label: const Text('새 폴더 추가'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

// Dialog to create a new favorite folder with name and emoji
void _showCreateFolderDialog(BuildContext context, WidgetRef ref) {
  final nameController = TextEditingController();
  final emojis = ['🍱', '🍜', '🍣', '🚇', '🛍️', '📌', '💡', '🗺️', '⚠️', '🇯🇵', '⭐', '📍'];
  String selectedEmoji = emojis.first;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('새 즐겨찾기 폴더'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '폴더 이름',
                      hintText: '예: 맛집 탐방, 교통 수단',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '아이콘 이모지 선택',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    width: 300,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: emojis.length,
                      itemBuilder: (context, index) {
                        final emoji = emojis[index];
                        final isSelected = selectedEmoji == emoji;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedEmoji = emoji;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : null,
                              border: Border.all(
                                color: isSelected ? colorScheme.primary : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    ref.read(favoritesProvider.notifier).createFolder(name, selectedEmoji);
                    Navigator.pop(context);
                  }
                },
                child: const Text('만들기'),
              ),
            ],
          );
        },
      );
    },
  );
}
