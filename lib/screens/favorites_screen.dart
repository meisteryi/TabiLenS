import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/favorites_provider.dart';
import '../providers/image_provider.dart';
import '../providers/gemini_provider.dart';
import 'package:flutter/foundation.dart';
import 'result_screen.dart';
import '../core/localization/app_strings.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(favoritesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = ref.watch(l10nProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.favoritesTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: folders.every((f) => f.items.isEmpty) && folders.length == 1
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.star_border_rounded,
                      size: 64,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.emptyFavoritesTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.emptyFavoritesDesc,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: folders.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final folder = folders[index];
                if (folder.items.isEmpty && folder.id != 'default') {
                  // Only show non-empty folders, or the default folder always
                  return const SizedBox.shrink();
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colorScheme.onSurface.withValues(alpha: 0.05),
                    ),
                  ),
                  child: ExpansionTile(
                    leading: Text(
                      folder.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      folder.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      l10n.itemsCount(folder.items.length),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    shape: const Border(),
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    children: folder.items.isEmpty
                        ? [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(l10n.emptyFolderDesc),
                              ),
                            )
                          ]
                        : folder.items.map((item) {
                            return Dismissible(
                              key: Key(item.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: colorScheme.error,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              onDismissed: (direction) {
                                ref.read(favoritesProvider.notifier).removeFromFolder(folder.id, item.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.removedFromFolder(folder.name)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: colorScheme.onSurface.withValues(alpha: 0.05),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: kIsWeb
                                        ? Image.network(
                                            item.imagePath,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image_rounded),
                                          )
                                        : Image.file(
                                            File(item.imagePath),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image_rounded),
                                          ),
                                  ),
                                ),
                                title: Text(
                                  item.result.translation,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  item.result.originalText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontFamily: 'monospace',
                                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                                onTap: () {
                                  ref.read(imageProvider.notifier).clear();
                                  ref.read(imageProvider.notifier).setImage(XFile(item.imagePath));
                                  ref.read(geminiNotifierProvider.notifier).setLoadedResult(item.result);
                                  
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const ResultScreen(popToFirst: false),
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                  ),
                );
              },
            ),
    );
  }
}
