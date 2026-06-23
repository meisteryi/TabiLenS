import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/image_provider.dart';
import 'history_screen.dart';
import 'text_selection_screen.dart';
import '../providers/text_selection_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _handleImageSelection(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    try {
      final imageNotifier = ref.read(imageProvider.notifier);
      await imageNotifier.pickImage(source);

      final selectedImage = ref.read(imageProvider);
      if (selectedImage != null && context.mounted) {
        // Trigger block detection
        ref.read(textSelectionProvider.notifier).detectBlocks(selectedImage);

        // Navigate to the selection screen
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const TextSelectionScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지를 가져오는 동안 오류가 발생했습니다: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: '번역 기록',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.08),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                // App Branding / Logo Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.translate_rounded,
                          size: 56,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'TabiLens',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 32,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '일본 현지 메뉴판과 간판 속 숨겨진\n문화적 맥락과 꿀팁을 읽어보세요',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Interaction Cards
                _BuildActionButton(
                  icon: Icons.camera_alt_rounded,
                  label: '카메라로 촬영하기',
                  subtitle: '현지 메뉴판, 길거리 간판 촬영',
                  color: colorScheme.primary,
                  onTap: () =>
                      _handleImageSelection(context, ref, ImageSource.camera),
                ),
                const SizedBox(height: 16),
                _BuildActionButton(
                  icon: Icons.photo_library_rounded,
                  label: '갤러리에서 선택하기',
                  subtitle: '저장된 이미지 번역 및 해설',
                  color: colorScheme.secondary,
                  onTap: () =>
                      _handleImageSelection(context, ref, ImageSource.gallery),
                ),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'Gemini 1.5 Flash Vision AI 기반 작동',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BuildActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _BuildActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.15),
              width: 1.5,
            ),
            color: colorScheme.surface.withValues(alpha: 0.8),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
