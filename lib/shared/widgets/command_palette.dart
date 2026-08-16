import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:void_app/core/theme/app_colors.dart';
import 'package:void_app/core/theme/app_typography.dart';
import 'package:void_app/features/collections/presentation/providers/collection_providers.dart';
import 'package:void_app/features/collections/presentation/widgets/collection_editor_dialog.dart';
import 'package:void_app/features/import_export/presentation/widgets/import_export_dialog.dart';
import 'package:void_app/features/items/presentation/providers/item_providers.dart';
import 'package:void_app/features/media_search/presentation/widgets/media_search_dialog.dart';
import 'package:void_app/features/schemas/presentation/providers/schema_providers.dart';
import 'package:void_app/features/search/domain/search_result.dart';
import 'package:void_app/features/search/presentation/providers/search_provider.dart';

class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => const CommandPalette(),
    );
  }

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(localSearchProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final query = searchState.query.trim();
    final bool isQueryEmpty = query.isEmpty;

    final collectionsAsync = ref.watch(collectionsStreamProvider);
    final schemasAsync = ref.watch(schemasStreamProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 520),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Input Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: true,
                        style: AppTypography.bodyLarge.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Search items, collections, or quick actions...',
                          hintStyle: AppTypography.bodyLarge.copyWith(
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onChanged: (val) {
                          ref.read(localSearchProvider.notifier).search(val);
                          setState(() => _selectedIndex = 0);
                        },
                        onSubmitted: (_) {
                          if (searchState.results.isNotEmpty &&
                              _selectedIndex < searchState.results.length) {
                            _handleSelectResult(
                              searchState.results[_selectedIndex],
                            );
                          }
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Text(
                        'ESC',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Results List or Quick Actions
              Flexible(
                child: isQueryEmpty
                    ? _buildQuickActions(
                        context,
                        collectionsAsync.value ?? [],
                        schemasAsync.value ?? [],
                        isDark,
                      )
                    : _buildSearchResults(
                        searchState.results,
                        searchState.isLoading,
                        isDark,
                      ),
              ),

              // Footer Shortcut Hints
              const Divider(height: 1),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    _buildKeyHint('↑↓', 'Navigate', isDark),
                    const SizedBox(width: 14),
                    _buildKeyHint('↵', 'Select', isDark),
                    const SizedBox(width: 14),
                    _buildKeyHint('Esc', 'Close', isDark),
                    const Spacer(),
                    Text(
                      'VOID Quick Switcher',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyHint(String key, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Text(
            key,
            style: AppTypography.labelSmall.copyWith(
              fontSize: 10,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 11,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    List<dynamic> collections,
    List<dynamic> schemas,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      shrinkWrap: true,
      children: [
        _buildSectionHeader('QUICK ACTIONS', isDark),
        _buildActionTile(
          icon: Icons.travel_explore,
          title: 'Search & Add Online Media',
          subtitle: 'Search TMDB / Google Books to add to active collection',
          shortcut: 'Ctrl+N',
          isDark: isDark,
          onTap: () {
            Navigator.of(context).pop();
            final activeCol = ref.read(selectedCollectionProvider);
            if (activeCol != null) {
              MediaSearchDialog.show(context, collectionId: activeCol.id);
            } else {
              CollectionEditorDialog.show(context);
            }
          },
        ),
        _buildActionTile(
          icon: Icons.create_new_folder_outlined,
          title: 'New Collection',
          subtitle: 'Create a custom collection',
          isDark: isDark,
          onTap: () {
            Navigator.of(context).pop();
            CollectionEditorDialog.show(context);
          },
        ),
        _buildActionTile(
          icon: Icons.import_export,
          title: 'Import / Export Data',
          subtitle: 'Backup or restore JSON & CSV files',
          isDark: isDark,
          onTap: () {
            Navigator.of(context).pop();
            ImportExportDialog.show(context);
          },
        ),
        _buildActionTile(
          icon: Icons.settings_outlined,
          title: 'Settings & Preferences',
          subtitle: 'Theme, database stats, shortcuts',
          isDark: isDark,
          onTap: () {
            Navigator.of(context).pop();
            context.go('/settings');
          },
        ),
      ],
    );
  }

  Widget _buildSearchResults(
    List<SearchResult> results,
    bool isLoading,
    bool isDark,
  ) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No matching items, collections, or schemas found',
            style: AppTypography.bodyMedium.copyWith(
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final res = results[index];
        final isSelected = index == _selectedIndex;

        IconData iconData = Icons.insert_drive_file_outlined;
        if (res.type == SearchResultType.collection) {
          iconData = Icons.folder_outlined;
        } else if (res.type == SearchResultType.schema) {
          iconData = Icons.schema_outlined;
        }

        return InkWell(
          onTap: () => _handleSelectResult(res),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isSelected
                ? (isDark
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.08))
                : Colors.transparent,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      iconData,
                      size: 16,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        res.title,
                        style: AppTypography.titleSmall.copyWith(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        res.subtitle ?? '',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    res.type.name.toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          fontSize: 11,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    String? shortcut,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        size: 18,
        color:
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          color:
              isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
      ),
      trailing: shortcut != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Text(
                shortcut,
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  void _handleSelectResult(SearchResult result) {
    Navigator.of(context).pop();
    switch (result.type) {
      case SearchResultType.collection:
        context.go('/collection/${result.id}');
        break;
      case SearchResultType.schema:
        break;
      case SearchResultType.item:
        if (result.item != null && result.item!.collectionId != null) {
          ref.read(selectedItemIdProvider.notifier).state = result.item!.id;
          context.go('/collection/${result.item!.collectionId}');
        }
        break;
    }
  }
}
