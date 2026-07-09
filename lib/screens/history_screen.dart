import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/history_provider.dart';
import '../providers/image_provider.dart';
import '../providers/gemini_provider.dart';
import '../providers/favorites_provider.dart';
import '../data/models/history_item.dart';
import 'package:flutter/foundation.dart';
import 'result_screen.dart';
import '../core/localization/app_strings.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  String _formatDateTime(DateTime dt) {
    // Simple custom formatting: "MM/DD HH:MM"
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyList = ref.watch(historyProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = ref.watch(l10nProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (historyList.isNotEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.clearAllBtn),
                    content: Text(l10n.confirmClearAllTitle),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.cancelBtn),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(historyProvider.notifier).clearHistory();
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.error,
                        ),
                        child: Text(l10n.deleteBtn),
                      ),
                    ],
                  ),
                );
              },
              child: Text(
                l10n.clearAllBtn,
                style: TextStyle(color: colorScheme.error),
              ),
            ),
        ],
      ),
      body: historyList.isEmpty
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
                      Icons.history_toggle_off_rounded,
                      size: 64,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.emptyHistoryTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.emptyHistoryDesc,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: historyList.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final item = historyList[index];

                return Dismissible(
                  key: Key(item.id),
                  direction: DismissDirection.horizontal,
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.bookmark_add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  secondaryBackground: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      return true;
                    } else if (direction == DismissDirection.startToEnd) {
                      _showFolderSelectionBottomSheet(context, ref, item);
                      return false;
                    }
                    return false;
                  },
                  onDismissed: (direction) {
                    if (direction == DismissDirection.endToStart) {
                      ref.read(historyProvider.notifier).deleteHistory(item.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.itemDeleted),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colorScheme.onSurface.withValues(alpha: 0.05),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        // Pre-populate loaders with history data
                        ref.read(imageProvider.notifier).clear();
                        ref.read(imageProvider.notifier).setImage(XFile(item.imagePath));
                        ref.read(geminiNotifierProvider.notifier).setLoadedResult(item.result);
                        
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ResultScreen(popToFirst: false),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            // Image Thumbnail
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: colorScheme.onSurface.withValues(alpha: 0.1),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
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
                            const SizedBox(width: 16),
                            // Text Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.result.translation,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.result.originalText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Timestamp / Chevron
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatDateTime(item.timestamp),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 11,
                                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showFolderSelectionBottomSheet(
    BuildContext context,
    WidgetRef ref,
    HistoryItem item,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final folders = ref.watch(favoritesProvider);
            final l10n = ref.watch(l10nProvider);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.selectFavFolderTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.create_new_folder_outlined),
                          color: colorScheme.primary,
                          tooltip: l10n.addNewFolderBtn,
                          onPressed: () => _showCreateFolderDialog(context, ref),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (folders.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('No folders.'),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: folders.length,
                          itemBuilder: (context, index) {
                            final folder = folders[index];
                            final isAdded = ref
                                .read(favoritesProvider.notifier)
                                .isItemInFolder(
                                  folder.id,
                                  item.result.originalText,
                                );

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              leading: Text(
                                folder.emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                              title: Text(
                                folder.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(l10n.itemsCount(folder.items.length)),
                              trailing: Icon(
                                isAdded
                                    ? Icons.bookmark_added_rounded
                                    : Icons.bookmark_add_outlined,
                                color: isAdded
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withValues(
                                        alpha: 0.4,
                                      ),
                              ),
                              onTap: () {
                                ref
                                    .read(favoritesProvider.notifier)
                                    .toggleFavorite(
                                      folder.id,
                                      item.imagePath,
                                      item.result,
                                    );
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isAdded
                                          ? l10n.removedFromFolder(folder.name)
                                          : '${folder.name}: ${l10n.addedToFavs}',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateFolderDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final emojiController = TextEditingController();

    final l10n = ref.read(l10nProvider);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.newFavFolderTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.folderNameLabel,
                  hintText: l10n.folderHintText,
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emojiController,
                decoration: InputDecoration(
                  labelText: l10n.emojiSelectionLabel,
                  hintText: '예: 🍣, ⭐, 📁',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancelBtn),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                final emoji = emojiController.text.trim();
                if (name.isNotEmpty) {
                  ref
                      .read(favoritesProvider.notifier)
                      .createFolder(name, emoji);
                  Navigator.pop(context);
                }
              },
              child: Text(l10n.createBtn),
            ),
          ],
        );
      },
    );
  }
}
