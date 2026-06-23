import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/image_provider.dart';
import 'history_screen.dart';
import 'text_selection_screen.dart';
import '../providers/text_selection_provider.dart';

import 'favorites_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _animationStarted = false;

  @override
  void initState() {
    super.initState();
    // 1.2 seconds delay, then trigger slide up animation
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _animationStarted = true;
        });
      }
    });
  }

  Future<void> _handleImageSelection(
    BuildContext context,
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: AnimatedOpacity(
          opacity: _animationStarted ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 800),
          child: IconButton(
            icon: const Icon(Icons.star_border_rounded),
            tooltip: '즐겨찾기',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            },
          ),
        ),
        actions: [
          AnimatedOpacity(
            opacity: _animationStarted ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 800),
            child: IconButton(
              icon: const Icon(Icons.history_rounded),
              tooltip: '번역 기록',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
            ),
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
          child: Stack(
            children: [
              // 1. Splash / Logo Header (starts centered, slides up to top)
              AnimatedAlign(
                alignment: _animationStarted
                    ? const Alignment(0, -0.45)
                    : Alignment.center,
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOutCubic,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                        'TabiLenS',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 32,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '일본 현지 메뉴판이 읽기 힘드신가요?\n음식의 이름과 꿀팁을 읽어보세요.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Action Buttons & Version Text (fade in & slide up from bottom)
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedOpacity(
                  opacity: _animationStarted ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 800),
                  child: AnimatedSlide(
                    offset: _animationStarted
                        ? Offset.zero
                        : const Offset(0, 0.15),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _BuildActionButton(
                            icon: Icons.camera_alt_rounded,
                            label: '카메라로 촬영하기',
                            subtitle: '현지 메뉴를 촬영해 주세요',
                            color: colorScheme.primary,
                            onTap: () => _handleImageSelection(
                              context,
                              ImageSource.camera,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _BuildActionButton(
                            icon: Icons.photo_library_rounded,
                            label: '갤러리에서 선택하기',
                            subtitle: '저장된 이미지에서 번역!',
                            color: colorScheme.secondary,
                            onTap: () => _handleImageSelection(
                              context,
                              ImageSource.gallery,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Center(
                            child: Text(
                              'Gemini 기반 텍스트 인식 및 번역',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 11,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
