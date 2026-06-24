import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/image_provider.dart';
import 'history_screen.dart';
import 'text_selection_screen.dart';
import '../providers/text_selection_provider.dart';
import '../providers/language_provider.dart';

import 'favorites_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _animationStarted = false;
  final PageController _pageController = PageController(initialPage: 3);

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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

    final activeLang = ref.watch(languageProvider);
    Color activeColor = colorScheme.primary;
    int activeLangIndex = 3; // Default to Japanese (index 3)
    if (activeLang == LanguageMode.french) {
      activeColor = const Color(0xFFEC407A); // Pink
      activeLangIndex = 0;
    } else if (activeLang == LanguageMode.spanish) {
      activeColor = const Color(0xFFD48F00); // Dark yellow
      activeLangIndex = 1;
    } else if (activeLang == LanguageMode.english) {
      activeColor = Colors.blue.shade600;
      activeLangIndex = 2;
    } else if (activeLang == LanguageMode.chinese) {
      activeColor = const Color.fromARGB(255, 255, 40, 40);
      activeLangIndex = 4;
    }

    String titleText = 'JPN';
    if (activeLang == LanguageMode.french) {
      titleText = 'FRA';
    } else if (activeLang == LanguageMode.spanish) {
      titleText = 'ESP';
    } else if (activeLang == LanguageMode.english) {
      titleText = 'ENG';
    } else if (activeLang == LanguageMode.chinese) {
      titleText = 'CHI';
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: AnimatedOpacity(
          opacity: _animationStarted ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 800),
          child: Text(
            titleText,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
        ),
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
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [activeColor.withValues(alpha: 0.20), colorScheme.surface],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 1. Splash / Logo Header (starts centered, slides up to top) with PageView
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
                      SizedBox(
                        height: 160,
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (index) {
                            final notifier = ref.read(
                              languageProvider.notifier,
                            );
                            if (index == 0) {
                              notifier.setLanguage(LanguageMode.french);
                            } else if (index == 1) {
                              notifier.setLanguage(LanguageMode.spanish);
                            } else if (index == 2) {
                              notifier.setLanguage(LanguageMode.english);
                            } else if (index == 3) {
                              notifier.setLanguage(LanguageMode.japanese);
                            } else if (index == 4) {
                              notifier.setLanguage(LanguageMode.chinese);
                            }
                          },
                          children: [
                            // French
                            _buildLogoPage(
                              theme: theme,
                              color: const Color(0xFFEC407A),
                              title: 'TabiLenS',
                              subtitle:
                                  '프랑스어 현지 메뉴판이 읽기 힘드신가요?\n음식의 이름과 꿀팁을 읽어보세요.',
                              topLeftChar: 'Ç',
                              bottomRightChar: '밥',
                            ),
                            // Spanish
                            _buildLogoPage(
                              theme: theme,
                              color: const Color(0xFFD48F00),
                              title: 'TabiLenS',
                              subtitle:
                                  '스페인어 현지 메뉴판이 읽기 힘드신가요?\n음식의 이름과 꿀팁을 읽어보세요.',
                              topLeftChar: 'Ñ',
                              bottomRightChar: '밥',
                            ),
                            // English
                            _buildLogoPage(
                              theme: theme,
                              color: Colors.blue.shade600,
                              title: 'TabiLenS',
                              subtitle:
                                  '영어 현지 메뉴판이 읽기 힘드신가요?\n음식의 이름과 꿀팁을 읽어보세요.',
                              topLeftChar: 'E',
                              bottomRightChar: '밥',
                            ),
                            // Japanese
                            _buildLogoPage(
                              theme: theme,
                              color: colorScheme.primary,
                              title: 'TabiLenS',
                              subtitle:
                                  '일본어 현지 메뉴판이 읽기 힘드신가요?\n음식의 이름과 꿀팁을 읽어보세요.',
                              topLeftChar: '飯',
                              bottomRightChar: '밥',
                            ),
                            // Chinese
                            _buildLogoPage(
                              theme: theme,
                              color: const Color.fromARGB(255, 255, 40, 40),
                              title: 'TabiLenS',
                              subtitle:
                                  '중국어 현지 메뉴판이 읽기 힘드신가요?\n음식의 이름과 꿀팁을 읽어보세요.',
                              topLeftChar: '饭',
                              bottomRightChar: '밥',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Dot indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final isActive = activeLangIndex == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: isActive ? 18 : 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? activeColor
                                  : colorScheme.onSurface.withValues(
                                      alpha: 0.2,
                                    ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
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
                            subtitle: '${activeLang.name} 메뉴를 촬영해 주세요',
                            color: activeColor,
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
                            color: activeColor.withValues(alpha: 0.8),
                            onTap: () => _handleImageSelection(
                              context,
                              ImageSource.gallery,
                            ),
                          ),
                          const SizedBox(height: 20),
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

  Widget _buildCustomTranslateIcon({
    required Color color,
    required String topLeftChar,
    required String bottomRightChar,
  }) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        children: [
          // 1. Left-Top Speech Bubble (Source Language)
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                  bottomLeft: Radius.circular(2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 3,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  topLeftChar,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
          // 2. Right-Bottom Speech Bubble (Target Language - Korean)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: color, width: 1.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 3,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  bottomRightChar,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoPage({
    required ThemeData theme,
    required Color color,
    required String title,
    required String subtitle,
    required String topLeftChar,
    required String bottomRightChar,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: _buildCustomTranslateIcon(
            color: color,
            topLeftChar: topLeftChar,
            bottomRightChar: bottomRightChar,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 28,
            letterSpacing: -1.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
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
