import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/translation_result.dart';
import 'shared_preferences_provider.dart';

class FavoriteItem {
  final String id;
  final String imagePath;
  final TranslationResult result;
  final DateTime timestamp;

  FavoriteItem({
    required this.id,
    required this.imagePath,
    required this.result,
    required this.timestamp,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id']?.toString() ?? '',
      imagePath: json['image_path']?.toString() ?? '',
      result: TranslationResult.fromJson(json['result'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_path': imagePath,
      'result': result.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class FavoriteFolder {
  final String id;
  final String name;
  final String emoji;
  final List<FavoriteItem> items;

  FavoriteFolder({
    required this.id,
    required this.name,
    required this.emoji,
    required this.items,
  });

  FavoriteFolder copyWith({
    String? name,
    String? emoji,
    List<FavoriteItem>? items,
  }) {
    return FavoriteFolder(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      items: items ?? this.items,
    );
  }

  factory FavoriteFolder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return FavoriteFolder(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      emoji: json['emoji']?.toString() ?? '',
      items: rawItems
          .map((item) => FavoriteItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class FavoritesNotifier extends Notifier<List<FavoriteFolder>> {
  static const _storageKey = 'favorite_folders';

  @override
  List<FavoriteFolder> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final favJsonString = prefs.getString(_storageKey);
    if (favJsonString != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(favJsonString);
        return decodedList
            .map((folder) => FavoriteFolder.fromJson(folder as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // Fallback to default folder if decode fails
      }
    }
    return [
      FavoriteFolder(
        id: 'default',
        name: '기본 즐겨찾기',
        emoji: '⭐',
        items: [],
      ),
    ];
  }

  void _saveToStorage(List<FavoriteFolder> folders) {
    final prefs = ref.read(sharedPreferencesProvider);
    final jsonString = jsonEncode(folders.map((f) => f.toJson()).toList());
    prefs.setString(_storageKey, jsonString);
  }

  void createFolder(String name, String emoji) {
    final newFolder = FavoriteFolder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      emoji: emoji.isEmpty ? '📁' : emoji,
      items: [],
    );
    state = [...state, newFolder];
    _saveToStorage(state);
  }

  void deleteFolder(String id) {
    if (id == 'default') return;
    state = state.where((f) => f.id != id).toList();
    _saveToStorage(state);
  }

  void toggleFavorite(String folderId, String imagePath, TranslationResult result) {
    state = state.map((folder) {
      if (folder.id == folderId) {
        final index = folder.items.indexWhere((item) => item.result.originalText == result.originalText);
        if (index != -1) {
          // Remove if already exists in this folder
          final updatedItems = List<FavoriteItem>.from(folder.items)..removeAt(index);
          return folder.copyWith(items: updatedItems);
        } else {
          // Add if not exists
          final newItem = FavoriteItem(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            imagePath: imagePath,
            result: result,
            timestamp: DateTime.now(),
          );
          return folder.copyWith(items: [...folder.items, newItem]);
        }
      }
      return folder;
    }).toList();
    _saveToStorage(state);
  }

  void removeFromFolder(String folderId, String itemId) {
    state = state.map((folder) {
      if (folder.id == folderId) {
        return folder.copyWith(
          items: folder.items.where((item) => item.id != itemId).toList(),
        );
      }
      return folder;
    }).toList();
    _saveToStorage(state);
  }

  bool isItemInFolder(String folderId, String originalText) {
    final folder = state.firstWhere((f) => f.id == folderId);
    return folder.items.any((item) => item.result.originalText == originalText);
  }

  bool isBookmarked(String originalText) {
    return state.any((folder) => folder.items.any((item) => item.result.originalText == originalText));
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, List<FavoriteFolder>>(() {
  return FavoritesNotifier();
});


