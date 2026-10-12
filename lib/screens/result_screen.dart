import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/image_provider.dart';
import '../providers/gemini_provider.dart';
import '../providers/text_selection_provider.dart';
import '../data/services/tts_service.dart';
import '../providers/favorites_provider.dart';
import '../data/models/translation_result.dart';
import 'package:flutter/foundation.dart';
import '../core/localization/app_strings.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final bool popToFirst;
  final Uint8List? croppedImageBytes;

  const ResultScreen({
    super.key,
    this.popToFirst = true,
    this.croppedImageBytes,
  });

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  int _selectedItemIndex = 0;

  @override
  Widget build(BuildContext context) {
    final selectedImage = ref.watch(imageProvider);
    final geminiState = ref.watch(geminiNotifierProvider);
    final isTtsSpeaking = ref.watch(ttsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = ref.watch(l10nProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analysisResultTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            ref.read(geminiNotifierProvider.notifier).reset();
            ref.read(textSelectionProvider.notifier).clear();
            ref.read(imageProvider.notifier).clear();
            if (widget.popToFirst) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          geminiState.maybeWhen(
            data: (result) {
              if (result == null) return const SizedBox.shrink();
              final allItems = result.allItems;
              final safeIndex = _selectedItemIndex.clamp(0, allItems.length - 1);
              final currentItem = allItems[safeIndex];

              final isBookmarked = ref.watch(favoritesProvider).any(
                    (folder) => folder.items.any(
                      (item) => item.result.originalText == currentItem.originalText,
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
                    currentItem,
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
        loading: () => _BuildLoadingState(
          imagePath: selectedImage?.path,
          croppedImageBytes: widget.croppedImageBytes,
        ),
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
            return _BuildLoadingState(
              imagePath: selectedImage?.path,
              croppedImageBytes: widget.croppedImageBytes,
            );
          }

          final allItems = result.allItems;
          final safeIndex = _selectedItemIndex.clamp(0, allItems.length - 1);
          final currentItem = allItems[safeIndex];

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Display cropped image (if user cropped an area) or input image
                if (widget.croppedImageBytes != null)
                  Container(
                    height: 220,
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Center(
                            child: Image.memory(
                              widget.croppedImageBytes!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.crop_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  '선택 크롭 영역',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (selectedImage != null)
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
                                l10n.imageLoadError,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.imageMissingDesc,
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
                      // Multi-item selector header if more than 1 item detected
                      if (allItems.length > 1) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.restaurant_menu_rounded,
                                      size: 18,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '선택 영역 내 메뉴 원어 목록 (${allItems.length}개)',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${safeIndex + 1} / ${allItems.length}',
                                      style: TextStyle(
                                        color: colorScheme.onPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: List.generate(allItems.length, (idx) {
                                    final item = allItems[idx];
                                    final isSelected = idx == safeIndex;
                                    final original = item.originalText.trim();
                                    final translation = item.translation.trim();
                                    final String chipLabel;
                                    if (original.isNotEmpty &&
                                        translation.isNotEmpty &&
                                        original != translation) {
                                      chipLabel = '${idx + 1}. $original ($translation)';
                                    } else if (original.isNotEmpty) {
                                      chipLabel = '${idx + 1}. $original';
                                    } else {
                                      chipLabel = '${idx + 1}. $translation';
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(
                                          chipLabel,
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 13,
                                            color: isSelected
                                                ? colorScheme.onPrimary
                                                : colorScheme.onSurface,
                                          ),
                                        ),
                                        selected: isSelected,
                                        selectedColor: colorScheme.primary,
                                        backgroundColor: colorScheme.surfaceContainerHighest,
                                        showCheckmark: false,
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(() {
                                              _selectedItemIndex = idx;
                                            });
                                          }
                                        },
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // 1. Original Text Card
                      _BuildResultCard(
                        title: l10n.originalTextLabel,
                        icon: Icons.language_rounded,
                        iconColor: colorScheme.secondary,
                        content: currentItem.originalText,
                        contentStyle: theme.textTheme.bodyLarge?.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                        action: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.copy_rounded,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: currentItem.originalText),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.copiedToClipboard),
                                  ),
                                );
                              },
                            ),
                            IconButton(
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
                                  ttsNotifier.speak(currentItem.originalText);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Translation Card
                      _BuildResultCard(
                        title: l10n.translationLabel,
                        icon: Icons.translate_rounded,
                        iconColor: colorScheme.primary,
                        content: currentItem.translation,
                        contentStyle: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        action: IconButton(
                          icon: Icon(
                            Icons.copy_rounded,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: currentItem.translation),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.copiedToClipboard),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. Cultural Context Card
                      _BuildResultCard(
                        title: l10n.explanationLabel,
                        icon: Icons.auto_awesome_rounded,
                        iconColor: Colors.amber.shade700,
                        content: currentItem.context,
                        contentStyle: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),

                      // 3.5. Order Phrase Card
                      if (currentItem.orderPhraseJapanese.isNotEmpty) ...[
                        _BuildResultCard(
                          title: l10n.orderPhraseTitle,
                          icon: Icons.chat_bubble_outline_rounded,
                          iconColor: Colors.deepPurple,
                          action: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.copy_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text: currentItem.orderPhraseJapanese,
                                    ),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.copiedToClipboard),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
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
                                    ttsNotifier.speak(
                                      currentItem.orderPhraseJapanese,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentItem.orderPhraseJapanese,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '[${l10n.orderPhrasePronunciationLabel}] ${currentItem.orderPhrasePronunciation}',
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
                                '${l10n.orderPhraseMeaningLabel}: ${currentItem.orderPhraseTranslation}',
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
                        title: l10n.tipsTitle,
                        icon: Icons.lightbulb_rounded,
                        iconColor: Colors.teal,
                        content: currentItem.tip,
                        contentStyle: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),

                      // 5. Allergy Information Card (맨 아래 섹션)
                      _BuildResultCard(
                        title: l10n.allergyInfoLabel,
                        icon: Icons.health_and_safety_rounded,
                        iconColor: Colors.deepOrange,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.deepOrange.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.deepOrange,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentItem.allergyInfo.isNotEmpty
                                          ? currentItem.allergyInfo
                                          : '주요 알레르기 유발 성분(대두, 밀, 계란 등)이 포함될 수 있으니 섭취 시 주의하세요.',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        height: 1.5,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 5. Multi-item Previous / Next Navigation Buttons
                      if (allItems.length > 1) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: safeIndex > 0
                                    ? () {
                                        setState(() {
                                          _selectedItemIndex = safeIndex - 1;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                                label: const Text('이전 메뉴'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: safeIndex < allItems.length - 1
                                    ? () {
                                        setState(() {
                                          _selectedItemIndex = safeIndex + 1;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                                label: const Text('다음 메뉴'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
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

class _BuildLoadingState extends ConsumerWidget {
  final String? imagePath;
  final Uint8List? croppedImageBytes;

  const _BuildLoadingState({
    this.imagePath,
    this.croppedImageBytes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = ref.watch(l10nProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (croppedImageBytes != null)
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: Image.memory(
                croppedImageBytes!,
                fit: BoxFit.cover,
              ),
            ),
          )
        else if (imagePath != null && (kIsWeb || File(imagePath!).existsSync()))
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
                l10n.analyzingText,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.analyzingDesc,
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

class _BuildErrorState extends ConsumerWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const _BuildErrorState({required this.errorMessage, required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = ref.watch(l10nProvider);

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
              l10n.errorAnalyzing,
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
              label: Text(l10n.retryBtn),
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
          final l10n = ref.watch(l10nProvider);

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
                      l10n.selectFavFolderTitle,
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
                  label: Text(l10n.addNewFolderBtn),
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
  final l10n = ref.read(l10nProvider);

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(l10n.newFavFolderTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l10n.folderNameLabel,
                      hintText: l10n.folderHintText,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.emojiSelectionLabel,
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
                child: Text(l10n.cancelBtn),
              ),
              TextButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    ref.read(favoritesProvider.notifier).createFolder(name, selectedEmoji);
                    Navigator.pop(context);
                  }
                },
                child: Text(l10n.createBtn),
              ),
            ],
          );
        },
      );
    },
  );
}
