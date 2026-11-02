import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/image_provider.dart';
import 'history_screen.dart';
import 'text_selection_screen.dart';
import '../providers/text_selection_provider.dart';
import '../providers/language_provider.dart';
import '../providers/shared_preferences_provider.dart';
import '../core/localization/app_strings.dart';

import 'favorites_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _animationStarted = false;
  bool _isUserLanguageSetup = false;
  UserLanguage? _selectedUserLanguage;
  bool _isUserLangDropdownOpen = false;
  final LayerLink _userLangLayerLink = LayerLink();
  OverlayEntry? _userLangDropdownOverlay;
  double _userLangDropdownHeight = 0;

  bool _isInitialSetup = false;
  LanguageMode? _selectedSetupLanguage;
  bool _isSetupDropdownOpen = false;
  final LayerLink _layerLink = LayerLink();
  bool _isMainDropdownOpen = false;
  final LayerLink _mainLayerLink = LayerLink();

  OverlayEntry? _setupDropdownOverlay;
  double _setupDropdownHeight = 0;
  OverlayEntry? _mainDropdownOverlay;
  double _mainDropdownHeight = 0;

  @override
  void initState() {
    super.initState();
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final hasUserLang = prefs.getString('user_language') != null;
      final hasSetup = prefs.getBool('has_completed_language_setup') ?? false;
      if (!hasUserLang) {
        _isUserLanguageSetup = true;
        _selectedUserLanguage = UserLanguage.korean;
      } else if (!hasSetup) {
        _isInitialSetup = true;
        _selectedSetupLanguage = LanguageMode.japanese;
      } else {
        // 1.2 seconds delay, then trigger slide up animation
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) {
            setState(() {
              _animationStarted = true;
            });
          }
        });
      }
    } catch (e, stack) {
      debugPrint('Error in initState: $e\n$stack');
      // Fallback: Default to completed setup state to prevent screen lockup
      _isInitialSetup = false;
      _isUserLanguageSetup = false;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _animationStarted = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _closeUserLangDropdown();
    _closeSetupDropdown();
    _closeMainDropdown();
    super.dispose();
  }

  void _openSetupDropdown() {
    if (_setupDropdownOverlay != null) return;
    
    setState(() {
      _isSetupDropdownOpen = true;
      _setupDropdownHeight = 0;
    });

    _setupDropdownOverlay = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final activeLang = _selectedSetupLanguage ?? LanguageMode.japanese;
        final activeColor = _getLanguageColor(activeLang, colorScheme);
        final screenWidth = MediaQuery.of(context).size.width;
        final setupModes = LanguageMode.values.where(
          (mode) => mode.englishName != _selectedUserLanguage?.englishName,
        ).toList();

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeSetupDropdown,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 58),
              child: Align(
                alignment: Alignment.topLeft,
                widthFactor: 1.0,
                heightFactor: 1.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: screenWidth - 48,
                  height: _setupDropdownHeight,
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: activeColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: setupModes.map((mode) {
                          final isSelected = _selectedSetupLanguage == mode;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedSetupLanguage = mode;
                                });
                                _closeSetupDropdown();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                color: isSelected
                                    ? activeColor.withValues(alpha: 0.15)
                                    : null,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getLanguageColor(mode, colorScheme),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _getCountryDisplayName(mode),
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_setupDropdownOverlay!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_setupDropdownOverlay != null) {
        final setupModesCount = LanguageMode.values.where(
          (mode) => mode.englishName != _selectedUserLanguage?.englishName,
        ).length;
        setState(() {
          _setupDropdownHeight = setupModesCount * 48.0;
        });
        _setupDropdownOverlay!.markNeedsBuild();
      }
    });
  }

  void _closeSetupDropdown() {
    if (_setupDropdownOverlay == null) return;

    setState(() {
      _isSetupDropdownOpen = false;
      _setupDropdownHeight = 0;
    });
    _setupDropdownOverlay!.markNeedsBuild();

    Future.delayed(const Duration(milliseconds: 250), () {
      if (_setupDropdownOverlay != null && !_isSetupDropdownOpen) {
        _setupDropdownOverlay!.remove();
        _setupDropdownOverlay = null;
      }
    });
  }

  void _openUserLangDropdown() {
    if (_userLangDropdownOverlay != null) return;
    
    setState(() {
      _isUserLangDropdownOpen = true;
      _userLangDropdownHeight = 0;
    });

    _userLangDropdownOverlay = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final screenWidth = MediaQuery.of(context).size.width;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeUserLangDropdown,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _userLangLayerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 58),
              child: Align(
                alignment: Alignment.topLeft,
                widthFactor: 1.0,
                heightFactor: 1.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: screenWidth - 48,
                  height: _userLangDropdownHeight,
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: UserLanguage.values.map((mode) {
                          final isSelected = _selectedUserLanguage == mode;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedUserLanguage = mode;
                                });
                                _closeUserLangDropdown();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                color: isSelected
                                    ? colorScheme.primary.withValues(alpha: 0.15)
                                    : null,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getUserLanguageColor(mode, colorScheme),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${mode.name} (${mode.englishName})',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_userLangDropdownOverlay!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_userLangDropdownOverlay != null) {
        setState(() {
          _userLangDropdownHeight = 240;
        });
        _userLangDropdownOverlay!.markNeedsBuild();
      }
    });
  }

  void _closeUserLangDropdown() {
    if (_userLangDropdownOverlay == null) return;

    setState(() {
      _isUserLangDropdownOpen = false;
      _userLangDropdownHeight = 0;
    });
    _userLangDropdownOverlay!.markNeedsBuild();

    Future.delayed(const Duration(milliseconds: 250), () {
      if (_userLangDropdownOverlay != null && !_isUserLangDropdownOpen) {
        _userLangDropdownOverlay!.remove();
        _userLangDropdownOverlay = null;
      }
    });
  }

  void _openMainDropdown() {
    if (_mainDropdownOverlay != null) return;

    setState(() {
      _isMainDropdownOpen = true;
      _mainDropdownHeight = 0;
    });

    _mainDropdownOverlay = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final activeLang = ref.read(languageProvider);
        final activeColor = _getLanguageColor(activeLang, colorScheme);
        final userLang = ref.read(userLanguageProvider);
        final filteredModes = LanguageMode.values.where(
          (mode) => mode.englishName != userLang.englishName,
        ).toList();

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeMainDropdown,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _mainLayerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 36),
              child: Align(
                alignment: Alignment.topLeft,
                widthFactor: 1.0,
                heightFactor: 1.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: 160,
                  height: _mainDropdownHeight,
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: activeColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: filteredModes.map((mode) {
                          final isSelected = activeLang == mode;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                ref.read(languageProvider.notifier).setLanguage(mode);
                                _closeMainDropdown();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                color: isSelected
                                    ? activeColor.withValues(alpha: 0.15)
                                    : null,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _getLanguageColor(mode, colorScheme),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _getCountryDisplayName(mode),
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 12,
                                          color: colorScheme.onSurface,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_mainDropdownOverlay!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mainDropdownOverlay != null) {
        final userLang = ref.read(userLanguageProvider);
        final filteredCount = LanguageMode.values.where(
          (mode) => mode.englishName != userLang.englishName,
        ).length;
        setState(() {
          _mainDropdownHeight = filteredCount * 40.0;
        });
        _mainDropdownOverlay!.markNeedsBuild();
      }
    });
  }

  void _closeMainDropdown() {
    if (_mainDropdownOverlay == null) return;

    setState(() {
      _isMainDropdownOpen = false;
      _mainDropdownHeight = 0;
    });
    _mainDropdownOverlay!.markNeedsBuild();

    Future.delayed(const Duration(milliseconds: 250), () {
      if (_mainDropdownOverlay != null && !_isMainDropdownOpen) {
        _mainDropdownOverlay!.remove();
        _mainDropdownOverlay = null;
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
        // Clear previous state so user can immediately view photo and drag desired area (0-sec load!)
        ref.read(textSelectionProvider.notifier).clear();

        // Navigate to the selection screen immediately
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

  static Color _getLanguageColor(LanguageMode lang, ColorScheme colorScheme) {
    switch (lang) {
      case LanguageMode.french:
        return const Color(0xFFEC407A);
      case LanguageMode.spanish:
        return const Color(0xFFD48F00);
      case LanguageMode.english:
        return Colors.blue.shade600;
      case LanguageMode.japanese:
        return colorScheme.primary;
      case LanguageMode.chinese:
        return const Color.fromARGB(255, 255, 40, 40);
    }
  }

  static Color _getUserLanguageColor(UserLanguage lang, ColorScheme colorScheme) {
    switch (lang) {
      case UserLanguage.korean:
        return const Color(0xFF009688); // Teal
      case UserLanguage.english:
        return Colors.blue.shade600; // Blue
      case UserLanguage.japanese:
        return colorScheme.primary; // Purple/Primary
      case UserLanguage.chinese:
        return const Color.fromARGB(255, 255, 40, 40); // Red
      case UserLanguage.spanish:
        return const Color(0xFFD48F00); // Amber
      case UserLanguage.french:
        return const Color(0xFFEC407A); // Pink
    }
  }

  static String _getCountryDisplayName(LanguageMode lang) {
    switch (lang) {
      case LanguageMode.french:
        return '프랑스 (France)';
      case LanguageMode.spanish:
        return '스페인 (Spain)';
      case LanguageMode.english:
        return '미국/영국 (USA/UK)';
      case LanguageMode.japanese:
        return '일본 (Japan)';
      case LanguageMode.chinese:
        return '중국 (China)';
    }
  }

  Widget _buildLogoPageForLanguage(
    LanguageMode lang,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isInitialSetup,
  ) {
    final l10n = ref.watch(l10nProvider);
    final setupL10n = _isUserLanguageSetup && _selectedUserLanguage != null
        ? AppStrings(_selectedUserLanguage!)
        : l10n;

    final subtitleText = isInitialSetup
        ? setupL10n.chooseTravelCountry
        : l10n.languageSubtitle(lang);

    switch (lang) {
      case LanguageMode.french:
        return _buildLogoPage(
          theme: theme,
          color: const Color(0xFFEC407A),
          title: 'TabiLenS',
          subtitle: subtitleText,
          topLeftChar: 'Ç',
          bottomRightChar: '밥',
          isInitialSetup: isInitialSetup,
        );
      case LanguageMode.spanish:
        return _buildLogoPage(
          theme: theme,
          color: const Color(0xFFD48F00),
          title: 'TabiLenS',
          subtitle: subtitleText,
          topLeftChar: 'Ñ',
          bottomRightChar: '밥',
          isInitialSetup: isInitialSetup,
        );
      case LanguageMode.english:
        return _buildLogoPage(
          theme: theme,
          color: Colors.blue.shade600,
          title: 'TabiLenS',
          subtitle: subtitleText,
          topLeftChar: 'E',
          bottomRightChar: '밥',
          isInitialSetup: isInitialSetup,
        );
      case LanguageMode.japanese:
        return _buildLogoPage(
          theme: theme,
          color: colorScheme.primary,
          title: 'TabiLenS',
          subtitle: subtitleText,
          topLeftChar: '飯',
          bottomRightChar: '밥',
          isInitialSetup: isInitialSetup,
        );
      case LanguageMode.chinese:
        return _buildLogoPage(
          theme: theme,
          color: const Color.fromARGB(255, 255, 40, 40),
          title: 'TabiLenS',
          subtitle: subtitleText,
          topLeftChar: '饭',
          bottomRightChar: '밥',
          isInitialSetup: isInitialSetup,
        );
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = ref.watch(l10nProvider);
    final setupL10n = _isUserLanguageSetup && _selectedUserLanguage != null
        ? AppStrings(_selectedUserLanguage!)
        : l10n;

    final activeLang = (_isInitialSetup || _isUserLanguageSetup)
        ? (_selectedSetupLanguage ?? LanguageMode.japanese)
        : ref.watch(languageProvider);
    final activeColor = _getLanguageColor(activeLang, colorScheme);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leadingWidth: 200,
        leading: IgnorePointer(
          ignoring: _isInitialSetup || _isUserLanguageSetup || !_animationStarted,
          child: AnimatedOpacity(
            opacity: _animationStarted && !_isInitialSetup && !_isUserLanguageSetup ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 800),
            child: Row(
              mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.star_border_rounded),
                tooltip: l10n.favoritesTitle,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FavoritesScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              CompositedTransformTarget(
                link: _mainLayerLink,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    debugPrint('Main dropdown tapped! Current state: $_isMainDropdownOpen');
                    if (_isMainDropdownOpen) {
                      _closeMainDropdown();
                    } else {
                      _openMainDropdown();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: activeColor.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getLanguageColor(activeLang, colorScheme),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 80),
                          child: Text(
                            _getCountryDisplayName(activeLang),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: _isMainDropdownOpen ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: activeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
                actions: [
          IgnorePointer(
            ignoring: _isInitialSetup || _isUserLanguageSetup || !_animationStarted,
            child: AnimatedOpacity(
              opacity: _animationStarted && !_isInitialSetup && !_isUserLanguageSetup ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 800),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: l10n.resetSetup,
                    onPressed: () async {
                      final prefs = ref.read(sharedPreferencesProvider);
                      await prefs.remove('has_completed_language_setup');
                      await prefs.remove('user_language');
                      setState(() {
                        _isUserLanguageSetup = true;
                        _selectedUserLanguage = UserLanguage.korean;
                        _isInitialSetup = false;
                        _selectedSetupLanguage = null;
                        _animationStarted = false;
                        _isMainDropdownOpen = false;
                        _isSetupDropdownOpen = false;
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.history_rounded),
                    tooltip: l10n.historyTitle,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const HistoryScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
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
              // 1. Splash / Logo Header (starts centered, slides up to top)
              AnimatedAlign(
                alignment: _animationStarted && !_isInitialSetup && !_isUserLanguageSetup
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
                        height: 220,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: const Offset(0, 0.1),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                child: child,
                              ),
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey(
                              '${activeLang.name}_${_isInitialSetup}_$_isUserLanguageSetup',
                            ),
                            child: _isUserLanguageSetup
                                ? _buildLogoPage(
                                    theme: theme,
                                    color: colorScheme.primary,
                                    title: 'TabiLenS',
                                    subtitle: setupL10n.chooseNativeLanguage,
                                    topLeftChar: 'A',
                                    bottomRightChar: 'あ',
                                    isInitialSetup: true,
                                  )
                                : _buildLogoPageForLanguage(
                                    activeLang,
                                    theme,
                                    colorScheme,
                                    _isInitialSetup,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Initial Setup Controls (dropdown + confirm button) at the bottom
              Align(
                alignment: const Alignment(0, 0.65),
                child: AnimatedOpacity(
                  opacity: (_isInitialSetup || _isUserLanguageSetup) ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 600),
                  child: AnimatedSlide(
                    offset: (_isInitialSetup || _isUserLanguageSetup)
                        ? Offset.zero
                        : const Offset(0, 0.15),
                    duration: const Duration(milliseconds: 600),
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
                          if (_isUserLanguageSetup) ...[
                            // User Language Dropdown for Initial Setup
                            CompositedTransformTarget(
                              link: _userLangLayerLink,
                              child: GestureDetector(
                                onTap: () {
                                  if (_isUserLangDropdownOpen) {
                                    _closeUserLangDropdown();
                                  } else {
                                    _openUserLangDropdown();
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface.withValues(
                                      alpha: 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: colorScheme.primary.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: _getUserLanguageColor(
                                                _selectedUserLanguage ?? UserLanguage.korean,
                                                colorScheme,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '${_selectedUserLanguage?.name ?? '한국어'} (${_selectedUserLanguage?.englishName ?? 'Korean'})',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      AnimatedRotation(
                                        turns: _isUserLangDropdownOpen ? 0.5 : 0.0,
                                        duration: const Duration(milliseconds: 300),
                                        child: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Confirm Button for User Language
                            Center(
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_selectedUserLanguage != null) {
                                      ref
                                          .read(userLanguageProvider.notifier)
                                          .setUserLanguage(_selectedUserLanguage!);
                                      final defaultSetupLang = LanguageMode.values.firstWhere(
                                        (mode) => mode.englishName != _selectedUserLanguage!.englishName,
                                        orElse: () => LanguageMode.japanese,
                                      );
                                      setState(() {
                                        _isUserLanguageSetup = false;
                                        _isInitialSetup = true;
                                        _selectedSetupLanguage = defaultSetupLang;
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shape: const CircleBorder(),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ] else if (_isInitialSetup) ...[
                            // Language Dropdown for Initial Setup
                            CompositedTransformTarget(
                              link: _layerLink,
                              child: GestureDetector(
                                onTap: () {
                                  if (_isSetupDropdownOpen) {
                                    _closeSetupDropdown();
                                  } else {
                                    _openSetupDropdown();
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface.withValues(
                                      alpha: 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: activeColor.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: _getLanguageColor(
                                                _selectedSetupLanguage ?? LanguageMode.japanese,
                                                colorScheme,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _getCountryDisplayName(
                                              _selectedSetupLanguage ?? LanguageMode.japanese,
                                            ),
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      AnimatedRotation(
                                        turns: _isSetupDropdownOpen ? 0.5 : 0.0,
                                        duration: const Duration(milliseconds: 300),
                                        child: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: activeColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Confirm Button (Circular shape matching user request)
                            Center(
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_selectedSetupLanguage != null) {
                                      ref
                                          .read(languageProvider.notifier)
                                          .setLanguage(_selectedSetupLanguage!);
                                      final prefs = ref.read(
                                        sharedPreferencesProvider,
                                      );
                                      prefs.setBool(
                                        'has_completed_language_setup',
                                        true,
                                      );
                                      setState(() {
                                        _isInitialSetup = false;
                                      });
                                      Future.delayed(
                                        const Duration(milliseconds: 100),
                                        () {
                                          if (mounted) {
                                            setState(() {
                                              _animationStarted = true;
                                            });
                                          }
                                        },
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: activeColor,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shape: const CircleBorder(),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Action Buttons & Version Text (fade in & slide up from bottom)
              IgnorePointer(
                ignoring: _isInitialSetup || _isUserLanguageSetup || !_animationStarted,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedOpacity(
                    opacity: _animationStarted && !_isInitialSetup && !_isUserLanguageSetup ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 800),
                    child: AnimatedSlide(
                      offset: _animationStarted && !_isInitialSetup && !_isUserLanguageSetup
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
                              label: l10n.cameraActionTitle,
                              subtitle: l10n.cameraActionSubtitle(activeLang),
                              color: activeColor,
                              onTap: () => _handleImageSelection(
                                context,
                                ImageSource.camera,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _BuildActionButton(
                              icon: Icons.photo_library_rounded,
                              label: l10n.galleryActionTitle,
                              subtitle: l10n.galleryActionSubtitle,
                              color: activeColor.withValues(alpha: 0.8),
                              onTap: () => _handleImageSelection(
                                context,
                                ImageSource.gallery,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: Text(
                                l10n.geminiPoweredFooter,
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
    bool isInitialSetup = false,
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: isInitialSetup
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.colorScheme.onSurface,
                  )
                : theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.3,
                  ),
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
