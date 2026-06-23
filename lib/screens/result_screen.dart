import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/image_provider.dart';
import '../providers/gemini_provider.dart';
import '../providers/text_selection_provider.dart';
import '../data/services/tts_service.dart';

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
            return const Center(child: Text('데이터가 없습니다.'));
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Display input image
                if (selectedImage != null)
                  Container(
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
                      child: Image.file(
                        File(selectedImage.path),
                        fit: BoxFit.cover,
                      ),
                    ),
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

  const _BuildResultCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.content,
    this.contentStyle,
    this.action,
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
        if (imagePath != null)
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.file(File(imagePath!), fit: BoxFit.cover),
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
