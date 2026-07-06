import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_preferences_provider.dart';

enum LanguageMode {
  french(name: '프랑스어', englishName: 'French', colorCode: 'pink'),
  spanish(name: '스페인어', englishName: 'Spanish', colorCode: 'yellow'),
  english(name: '영어', englishName: 'English', colorCode: 'blue'),
  japanese(name: '일본어', englishName: 'Japanese', colorCode: 'purple'),
  chinese(name: '중국어', englishName: 'Chinese', colorCode: 'red');

  final String name;
  final String englishName;
  final String colorCode;

  const LanguageMode({
    required this.name,
    required this.englishName,
    required this.colorCode,
  });
}

class LanguageNotifier extends StateNotifier<LanguageMode> {
  final Ref ref;

  LanguageNotifier(this.ref) : super(LanguageMode.japanese) {
    _loadLanguage();
  }

  void _loadLanguage() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final langName = prefs.getString('selected_language');
      if (langName != null) {
        state = LanguageMode.values.firstWhere((e) => e.name == langName);
      }
    } catch (_) {}
  }

  void setLanguage(LanguageMode mode) {
    state = mode;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      prefs.setString('selected_language', mode.name);
    } catch (_) {}
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, LanguageMode>((ref) {
  return LanguageNotifier(ref);
});

enum UserLanguage {
  korean(name: '한국어', englishName: 'Korean'),
  english(name: '영어', englishName: 'English'),
  japanese(name: '일본어', englishName: 'Japanese'),
  chinese(name: '중국어', englishName: 'Chinese'),
  spanish(name: '스페인어', englishName: 'Spanish'),
  french(name: '프랑스어', englishName: 'French');

  final String name;
  final String englishName;

  const UserLanguage({
    required this.name,
    required this.englishName,
  });
}

class UserLanguageNotifier extends StateNotifier<UserLanguage> {
  final Ref ref;

  UserLanguageNotifier(this.ref) : super(UserLanguage.korean) {
    _loadUserLanguage();
  }

  void _loadUserLanguage() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final langName = prefs.getString('user_language');
      if (langName != null) {
        state = UserLanguage.values.firstWhere((e) => e.name == langName);
      }
    } catch (_) {}
  }

  void setUserLanguage(UserLanguage mode) {
    state = mode;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      prefs.setString('user_language', mode.name);
    } catch (_) {}
  }
}

final userLanguageProvider = StateNotifierProvider<UserLanguageNotifier, UserLanguage>((ref) {
  return UserLanguageNotifier(ref);
});

