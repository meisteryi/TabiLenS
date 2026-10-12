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
import '../providers/language_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import '../core/localization/app_strings.dart';
import '../core/utils/currency_helper.dart';

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
  final Map<int, GlobalKey> _chipKeys = {};

  void _scrollToItem(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _chipKeys[index];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          alignment: 0.5,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _selectItem(int index) {
    setState(() {
      _selectedItemIndex = index;
    });
    _scrollToItem(index);
  }

  void _shareAnalysisResult(
    BuildContext context,
    TranslationResult result,
    LanguageMode currentLang,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('📋 [TabiLenS] 메뉴판 번역 & 여행 기록');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    for (int i = 0; i < result.allItems.length; i++) {
      final item = result.allItems[i];
      final priceInfo = CurrencyHelper.extractAndConvertPrice(
        item.originalText,
        languageMode: currentLang,
        explicitPrice: item.price,
      );
      buffer.writeln('${i + 1}. ${item.originalText}');
      buffer.writeln('   👉 번역: ${item.translation}');
      if (priceInfo != null) {
        buffer.writeln('   🏷️ 가격: ${priceInfo.originalPriceText} (${priceInfo.formattedKrw})');
      }
      if (item.context.isNotEmpty) {
        buffer.writeln('   💡 설명: ${item.context}');
      }
      if (item.allergyInfo.isNotEmpty) {
        buffer.writeln('   ⚠️ 알레르기/재료: ${item.allergyInfo}');
      }
      if (item.orderPhraseJapanese.isNotEmpty) {
        buffer.writeln('   🗣️ 추천 주문: ${item.orderPhraseJapanese}');
      }
      buffer.writeln();
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Shared via TabiLenS ✈️');

    final text = buffer.toString().trim();
    SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'TabiLenS 메뉴 번역 목록',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedImage = ref.watch(imageProvider);
    final geminiState = ref.watch(geminiNotifierProvider);
    final isTtsSpeaking = ref.watch(ttsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = ref.watch(l10nProvider);

    void handleBack() {
      ref.read(geminiNotifierProvider.notifier).reset();
      ref.read(textSelectionProvider.notifier).clear();
      ref.read(imageProvider.notifier).clear();
      if (widget.popToFirst) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        Navigator.of(context).pop();
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.analysisResultTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: handleBack,
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

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.share_rounded),
                    tooltip: '메뉴 목록 공유',
                    onPressed: () {
                      _shareAnalysisResult(
                        context,
                        result,
                        ref.read(languageProvider),
                      );
                    },
                  ),
                  IconButton(
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
                        croppedImageBytes: widget.croppedImageBytes,
                      );
                    },
                  ),
                ],
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
          final currentLang = ref.watch(languageProvider);
          final priceInfo = CurrencyHelper.extractAndConvertPrice(
            currentItem.originalText,
            languageMode: currentLang,
            explicitPrice: currentItem.price,
          );

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
                                    final itemPrice = CurrencyHelper.extractAndConvertPrice(
                                      item.originalText,
                                      languageMode: currentLang,
                                      explicitPrice: item.price,
                                    );
                                    final priceSuffix = itemPrice != null
                                        ? ' · ${itemPrice.originalPriceText}'
                                        : '';
                                    final String chipLabel;
                                    if (original.isNotEmpty &&
                                        translation.isNotEmpty &&
                                        original != translation) {
                                      chipLabel =
                                          '${idx + 1}. $original ($translation)$priceSuffix';
                                    } else if (original.isNotEmpty) {
                                      chipLabel = '${idx + 1}. $original$priceSuffix';
                                    } else {
                                      chipLabel = '${idx + 1}. $translation$priceSuffix';
                                    }

                                    return Padding(
                                      key: _chipKeys.putIfAbsent(idx, () => GlobalKey()),
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
                                            _selectItem(idx);
                                          }
                                        },
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Previous / Next buttons right below the selected area
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: safeIndex > 0
                                          ? () => _selectItem(safeIndex - 1)
                                          : null,
                                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                                      label: const Text('이전 메뉴'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 11),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: safeIndex < allItems.length - 1
                                          ? () => _selectItem(safeIndex + 1)
                                          : null,
                                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                      label: const Text('다음 메뉴'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: colorScheme.onPrimary,
                                        padding: const EdgeInsets.symmetric(vertical: 11),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentItem.translation,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (priceInfo != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.teal.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.payments_outlined,
                                      size: 18,
                                      color: Colors.teal,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${priceInfo.originalPriceText}  ➔  ${priceInfo.formattedKrw}',
                                      style: const TextStyle(
                                        color: Colors.teal,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
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
                                icon: const Icon(
                                  Icons.badge_outlined,
                                  color: Colors.deepPurple,
                                ),
                                tooltip: '주문 카드 모드 (점원에게 보여주기)',
                                onPressed: () {
                                  _showOrderCardModal(
                                    context,
                                    ref,
                                    currentItem,
                                  );
                                },
                              ),
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
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
    final isNetworkError = cleanMessage.toLowerCase().contains('socket') ||
        cleanMessage.toLowerCase().contains('host lookup') ||
        cleanMessage.toLowerCase().contains('connection') ||
        cleanMessage.toLowerCase().contains('clientexception') ||
        cleanMessage.toLowerCase().contains('network') ||
        cleanMessage.toLowerCase().contains('timeout');

    final displayTitle = isNetworkError ? '네트워크 연결 오류' : l10n.errorAnalyzing;
    final displayMessage = isNetworkError
        ? '인터넷 연결이 원활하지 않습니다. Wi-Fi 또는 모바일 데이터 연결을 확인하고 다시 시도해 주세요.'
        : cleanMessage;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNetworkError ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              size: 72,
              color: colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              displayTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              displayMessage,
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


class _OrderPhraseInfo {
  final String phrase;
  final String pronunciation;
  final String translation;

  const _OrderPhraseInfo({
    required this.phrase,
    required this.pronunciation,
    required this.translation,
  });
}

_OrderPhraseInfo _getDynamicOrderPhraseInfo(
  TranslationResult item,
  int quantity,
  LanguageMode lang,
) {
  if (quantity == 1) {
    return _OrderPhraseInfo(
      phrase: item.orderPhraseJapanese,
      pronunciation: item.orderPhrasePronunciation,
      translation: item.orderPhraseTranslation,
    );
  }

  // 1. Japanese
  if (lang == LanguageMode.japanese) {
    const jpQuantities = {
      2: '二つ',
      3: '三つ',
      4: '四つ',
      5: '五つ',
      6: '六つ',
      7: '七つ',
      8: '八つ',
      9: '九つ',
      10: '十個',
    };
    const jpPron = {
      2: '후타츠',
      3: '밋츠',
      4: '욧츠',
      5: '이츠츠',
      6: '뭇츠',
      7: '나나츠',
      8: '얏츠',
      9: '코코노츠',
      10: '쥬코',
    };

    final qWord = jpQuantities[quantity] ?? '$quantity個';
    final qPron = jpPron[quantity] ?? '$quantity코';

    String p = item.orderPhraseJapanese;
    if (p.contains('一つ')) {
      p = p.replaceAll('一つ', qWord);
    } else if (p.contains('1つ')) {
      p = p.replaceAll('1つ', qWord);
    } else if (p.contains('1個')) {
      p = p.replaceAll('1個', '$quantity個');
    } else if (p.contains('ひとつ')) {
      p = p.replaceAll('ひとつ', qWord);
    } else if (p.contains('1')) {
      p = p.replaceAll('1', quantity.toString());
    } else {
      p = '${item.originalText}を$qWordお願いします。';
    }

    String pron = item.orderPhrasePronunciation;
    if (pron.contains('히토츠')) {
      pron = pron.replaceAll('히토츠', qPron);
    } else if (pron.contains('히토쯔')) {
      pron = pron.replaceAll('히토쯔', qPron);
    } else if (pron.contains('하나')) {
      pron = pron.replaceAll('하나', '$quantity개');
    } else if (pron.isNotEmpty) {
      pron = '$pron ($qPron)';
    }

    String trans = item.orderPhraseTranslation;
    if (trans.contains('하나')) {
      trans = trans.replaceAll('하나', '$quantity개');
    } else if (trans.contains('한 개')) {
      trans = trans.replaceAll('한 개', '$quantity개');
    } else if (trans.contains('1개')) {
      trans = trans.replaceAll('1개', '$quantity개');
    } else {
      final name = item.translation.isNotEmpty ? item.translation : item.originalText;
      trans = '$name $quantity개 부탁합니다.';
    }

    return _OrderPhraseInfo(phrase: p, pronunciation: pron, translation: trans);
  }

  // 2. Chinese
  if (lang == LanguageMode.chinese) {
    const zhQuantities = {
      2: '两个',
      3: '三个',
      4: '四个',
      5: '五个',
      6: '六个',
      7: '七个',
      8: '八个',
      9: '九个',
      10: '十个',
    };
    const zhPron = {
      2: '량거',
      3: '산거',
      4: '쓰거',
      5: '우거',
      6: '리우거',
      7: '치거',
      8: '바거',
      9: '지우거',
      10: '스거',
    };

    final qWord = zhQuantities[quantity] ?? '$quantity个';
    final qPron = zhPron[quantity] ?? '$quantity거';

    String p = item.orderPhraseJapanese;
    if (p.contains('一个')) {
      p = p.replaceAll('一个', qWord);
    } else if (p.contains('1个')) {
      p = p.replaceAll('1个', qWord);
    } else if (p.contains('一份')) {
      p = p.replaceAll('一份', quantity == 2 ? '两份' : '$quantity份');
    } else if (p.contains('1')) {
      p = p.replaceAll('1', quantity.toString());
    } else {
      p = '请给我$qWord${item.originalText}。';
    }

    String pron = item.orderPhrasePronunciation;
    if (pron.contains('이거')) {
      pron = pron.replaceAll('이거', qPron);
    } else if (pron.contains('이펀')) {
      pron = pron.replaceAll('이펀', quantity == 2 ? '량펀' : '$quantity펀');
    } else if (pron.isNotEmpty) {
      pron = '$pron ($qPron)';
    }

    String trans = item.orderPhraseTranslation;
    if (trans.contains('하나')) {
      trans = trans.replaceAll('하나', '$quantity개');
    } else if (trans.contains('1개')) {
      trans = trans.replaceAll('1개', '$quantity개');
    } else {
      final name = item.translation.isNotEmpty ? item.translation : item.originalText;
      trans = '$name $quantity개 부탁합니다.';
    }

    return _OrderPhraseInfo(phrase: p, pronunciation: pron, translation: trans);
  }

  // 3. English
  if (lang == LanguageMode.english) {
    const enQuantities = {
      2: 'two',
      3: 'three',
      4: 'four',
      5: 'five',
      6: 'six',
      7: 'seven',
      8: 'eight',
      9: 'nine',
      10: 'ten',
    };
    final qWord = enQuantities[quantity] ?? '$quantity';

    String p = item.orderPhraseJapanese;
    if (p.toLowerCase().contains('one')) {
      p = p.replaceAll(RegExp(r'\bone\b', caseSensitive: false), qWord);
    } else if (p.contains('1')) {
      p = p.replaceAll('1', quantity.toString());
    } else {
      p = 'Can I have $qWord ${item.originalText}, please?';
    }

    String trans = item.orderPhraseTranslation;
    if (trans.contains('하나')) {
      trans = trans.replaceAll('하나', '$quantity개');
    } else if (trans.contains('1개')) {
      trans = trans.replaceAll('1개', '$quantity개');
    } else {
      final name = item.translation.isNotEmpty ? item.translation : item.originalText;
      trans = '$name $quantity개 부탁합니다.';
    }

    return _OrderPhraseInfo(
      phrase: p,
      pronunciation: item.orderPhrasePronunciation,
      translation: trans,
    );
  }

  // 4. French
  if (lang == LanguageMode.french) {
    const frQuantities = {
      2: 'deux',
      3: 'trois',
      4: 'quatre',
      5: 'cinq',
      6: 'six',
      7: 'sept',
      8: 'huit',
      9: 'neuf',
      10: 'dix',
    };
    final qWord = frQuantities[quantity] ?? '$quantity';

    String p = item.orderPhraseJapanese;
    if (p.toLowerCase().contains('un ')) {
      p = p.replaceAll(RegExp(r'\bun\b', caseSensitive: false), qWord);
    } else if (p.contains('1')) {
      p = p.replaceAll('1', quantity.toString());
    } else {
      p = '$qWord ${item.originalText}, s\'il vous plaît.';
    }

    String trans = item.orderPhraseTranslation;
    if (trans.contains('하나')) {
      trans = trans.replaceAll('하나', '$quantity개');
    } else {
      final name = item.translation.isNotEmpty ? item.translation : item.originalText;
      trans = '$name $quantity개 부탁합니다.';
    }

    return _OrderPhraseInfo(
      phrase: p,
      pronunciation: item.orderPhrasePronunciation,
      translation: trans,
    );
  }

  // 5. Spanish
  if (lang == LanguageMode.spanish) {
    const esQuantities = {
      2: 'dos',
      3: 'tres',
      4: 'cuatro',
      5: 'cinco',
      6: 'seis',
      7: 'siete',
      8: 'ocho',
      9: 'nueve',
      10: 'diez',
    };
    final qWord = esQuantities[quantity] ?? '$quantity';

    String p = item.orderPhraseJapanese;
    if (p.toLowerCase().contains('un ')) {
      p = p.replaceAll(RegExp(r'\bun\b', caseSensitive: false), qWord);
    } else if (p.contains('1')) {
      p = p.replaceAll('1', quantity.toString());
    } else {
      p = '$qWord ${item.originalText}, por favor.';
    }

    String trans = item.orderPhraseTranslation;
    if (trans.contains('하나')) {
      trans = trans.replaceAll('하나', '$quantity개');
    } else {
      final name = item.translation.isNotEmpty ? item.translation : item.originalText;
      trans = '$name $quantity개 부탁합니다.';
    }

    return _OrderPhraseInfo(
      phrase: p,
      pronunciation: item.orderPhrasePronunciation,
      translation: trans,
    );
  }

  return _OrderPhraseInfo(
    phrase: '${item.originalText} x $quantity',
    pronunciation: item.orderPhrasePronunciation,
    translation: '${item.translation} $quantity개',
  );
}

// Order card modal for showing to restaurant staff / waiters
void _showOrderCardModal(
  BuildContext context,
  WidgetRef ref,
  TranslationResult item,
) {
  int quantity = 1;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Consumer(
            builder: (context, ref, _) {
              final theme = Theme.of(context);
              final colorScheme = theme.colorScheme;
              final isTtsSpeaking = ref.watch(ttsProvider);
              final currentLang = ref.watch(languageProvider);
              final orderInfo = _getDynamicOrderPhraseInfo(
                item,
                quantity,
                currentLang,
              );

              return Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: EdgeInsets.only(
                  top: 16,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 28,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: colorScheme.onSurface.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.badge_rounded,
                              color: Colors.deepPurple,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '주문 카드 (점원 제시용)',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  '이 화면을 식당 직원에게 직접 보여주세요',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Main Order Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.deepPurple.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ORDER ITEM',
                                style: TextStyle(
                                  color: Colors.deepPurple,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Large original item text
                            Text(
                              item.originalText,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 26,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (item.translation.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                item.translation,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 18),
                            const Divider(height: 1),
                            const SizedBox(height: 16),

                            // Quantity Selector
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '수량 / 数量',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface.withValues(alpha: 0.75),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: colorScheme.outline.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_rounded, size: 20),
                                        onPressed: quantity > 1
                                            ? () => setModalState(() => quantity--)
                                            : null,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        child: Text(
                                          '$quantity',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_rounded, size: 20),
                                        onPressed: () => setModalState(() => quantity++),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (CurrencyHelper.extractAndConvertPrice(
                                  item.originalText,
                                  languageMode: currentLang,
                                  explicitPrice: item.price,
                                ) !=
                                null) ...[
                              const SizedBox(height: 14),
                              Builder(
                                builder: (context) {
                                  final modalPriceInfo =
                                      CurrencyHelper.extractAndConvertPrice(
                                    item.originalText,
                                    languageMode: currentLang,
                                    explicitPrice: item.price,
                                  )!;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.teal.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.payments_outlined,
                                          size: 18,
                                          color: Colors.teal,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          CurrencyHelper.formatMultiplied(
                                            modalPriceInfo,
                                            quantity,
                                          ),
                                          style: const TextStyle(
                                            color: Colors.teal,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                            const SizedBox(height: 18),

                            // Large Order sentence for waiter
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.deepPurple.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    orderInfo.phrase,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                      fontSize: 20,
                                      height: 1.3,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (orderInfo.pronunciation.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '[발음] ${orderInfo.pronunciation}',
                                      style: TextStyle(
                                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                  if (orderInfo.translation.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      '뜻: ${orderInfo.translation}',
                                      style: TextStyle(
                                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                                        fontSize: 13,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action buttons: Speak TTS to Waiter & Copy
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final tts = ref.read(ttsProvider.notifier);
                                if (isTtsSpeaking) {
                                  tts.stop();
                                } else {
                                  tts.speak(orderInfo.phrase);
                                }
                              },
                              icon: Icon(
                                isTtsSpeaking
                                    ? Icons.stop_circle_rounded
                                    : Icons.volume_up_rounded,
                                size: 20,
                              ),
                              label: Text(
                                isTtsSpeaking ? '음성 중지' : '점원에게 들려주기',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: orderInfo.phrase),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('주문 문구가 복사되었습니다'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              label: const Text('문구 복사'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

// Favorites management bottom sheet modal
void _showFavoritesBottomSheet(
  BuildContext context,
  WidgetRef ref,
  TranslationResult result,
  String imagePath, {
  Uint8List? croppedImageBytes,
}) {
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
                          ref.read(favoritesProvider.notifier).toggleFavorite(
                                folder.id,
                                imagePath,
                                result,
                                croppedImageBytes: croppedImageBytes,
                              );
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
