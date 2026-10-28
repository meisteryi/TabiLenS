import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/shared_preferences_provider.dart';
import 'core/theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env file)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // Fallback if .env is missing or cannot be loaded
    debugPrint('Error loading .env file: $e');
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Maximum width to simulate a realistic smartphone aspect ratio on desktop/web
  static const double maxMobileWidth = 460.0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TabiLens - Japan Tourist Guide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Adapts to user device preferences
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            // When viewed on desktop/PC browser with a wide viewport
            if (constraints.maxWidth > maxMobileWidth) {
              final double targetWidth = maxMobileWidth;
              final double targetHeight = constraints.maxHeight;
              final isDark = Theme.of(context).brightness == Brightness.dark;

              return Container(
                color: isDark ? const Color(0xFF0F1115) : const Color(0xFFE5E9EE),
                alignment: Alignment.center,
                child: Container(
                  width: targetWidth,
                  height: targetHeight,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.4 : 0.12,
                        ),
                        blurRadius: 30,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      size: Size(targetWidth, targetHeight),
                    ),
                    child: child,
                  ),
                ),
              );
            }

            // Normal mobile device viewport
            return child;
          },
        );
      },
      home: const HomeScreen(),
    );
  }
}
