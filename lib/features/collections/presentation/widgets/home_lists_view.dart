import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:void_app/app/app_providers.dart';
import 'package:void_app/core/theme/app_colors.dart';
import 'package:void_app/core/theme/app_typography.dart';
import 'package:void_app/features/collections/data/collection_repository.dart';
import 'package:void_app/features/collections/domain/collection.dart';
import 'package:void_app/features/collections/presentation/providers/collection_providers.dart';
import 'package:void_app/features/collections/presentation/widgets/collection_card.dart';
import 'package:void_app/features/collections/presentation/widgets/collection_editor_dialog.dart';
import 'package:void_app/features/collections/presentation/widgets/collection_list_tile.dart';
import 'package:void_app/features/items/data/item_repository.dart';
import 'package:void_app/features/items/domain/item.dart';
import 'package:void_app/features/items/presentation/providers/item_providers.dart';
import 'package:void_app/features/items/presentation/widgets/item_card.dart';
import 'package:void_app/features/items/presentation/widgets/item_detail_view.dart';
import 'package:void_app/features/items/presentation/widgets/item_list_tile.dart';
import 'package:void_app/features/search/presentation/providers/search_provider.dart';
import 'package:void_app/features/settings/domain/app_settings.dart';
import 'package:void_app/features/settings/presentation/providers/settings_provider.dart';
import 'package:void_app/shared/widgets/confirm_dialog.dart';
import 'package:void_app/shared/widgets/empty_state.dart';

class HomeListsView extends ConsumerStatefulWidget {
  const HomeListsView({super.key});

  @override
  ConsumerState<HomeListsView> createState() => _HomeListsViewState();
}

class _HomeListsViewState extends ConsumerState<HomeListsView> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final collectionsAsync = ref.watch(collectionsStreamProvider);
    final allItemsAsync = ref.watch(allItemsStreamProvider);
    final searchQuery =
        ref.watch(globalSearchQueryProvider).trim().toLowerCase();
    final settings = ref.watch(settingsProvider);
    final isListMode = settings.defaultViewMode == ItemViewMode.list;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: collectionsAsync.when(
        data: (collections) {
          final allItems = allItemsAsync.value ?? [];

          // Group preview items per collection for collage
          final Map<String, List<Item>> itemsByCollection = {};
          for (final item in allItems) {
            if (item.collectionId != null) {
              itemsByCollection
                  .putIfAbsent(item.collectionId!, () => [])
                  .add(item);
            }
          }

          final isSearching = searchQuery.isNotEmpty;
          final matchingCollections = isSearching
              ? collections
                  .where((c) => c.name.toLowerCase().contains(searchQuery))
                  .toList()
              : collections;

          final matchingItems = isSearching
              ? allItems
                  .where(
                    (item) =>
                        item.title.toLowerCase().contains(searchQuery),
                  )
                  .toList()
              : <Item>[];

          if (isSearching &&
              matchingCollections.isEmpty &&
              matchingItems.isEmpty) {
            return EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No Results Found',
              description: 'No collections or items match "$searchQuery".',
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = settings.gridColumns ??
                  (width / 165).floor().clamp(3, 12);

              // Mathematically exact child aspect ratio based on card width (2:3 box + 50px text)
              const horizontalPadding = 48.0; // 24 left + 24 right
              final totalSpacing = (crossAxisCount - 1) * 18.0;
              final columnWidth =
                  (width - horizontalPadding - totalSpacing) / crossAxisCount;
              final boxHeight = columnWidth * 1.5; // 2:3 ratio
              const textSectionHeight = 50.0;
              final totalCardHeight = boxHeight + textSectionHeight;
              final childAspectRatio =
                  (columnWidth / totalCardHeight).clamp(0.35, 0.75);

              if (isSearching) {
                return CustomScrollView(
                  slivers: [
                    if (matchingCollections.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                          child: Text(
                            'Collections (${matchingCollections.length})',
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      if (isListMode)
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final col = matchingCollections[index];
                              final previewItems =
                                  itemsByCollection[col.id] ?? [];
                              return CollectionListTile(
                                collection: col,
                                previewItems: previewItems,
                                onTap: () => _openCollection(col),
                                onEdit: () => CollectionEditorDialog.show(
                                  context,
                                  collection: col,
                                ),
                                onDelete: () => _deleteCollection(col),
                              );
                            },
                            childCount: matchingCollections.length,
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 18,
                              mainAxisSpacing: 20,
                              childAspectRatio: childAspectRatio,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final col = matchingCollections[index];
                                final previewItems =
                                    itemsByCollection[col.id] ?? [];

                                return CollectionCard(
                                  collection: col,
                                  previewItems: previewItems,
                                  onTap: () => _openCollection(col),
                                  onEdit: () => CollectionEditorDialog.show(
                                    context,
                                    collection: col,
                                  ),
                                  onDelete: () => _deleteCollection(col),
                                );
                              },
                              childCount: matchingCollections.length,
                            ),
                          ),
                        ),
                    ],
                    if (matchingItems.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                          child: Text(
                            'Items (${matchingItems.length})',
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      if (isListMode)
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = matchingItems[index];
                              return ItemListTile(
                                item: item,
                                onTap: () => _openItemDetail(context, item),
                                onEdit: () => _openItemDetail(context, item),
                                onDelete: () => _deleteItem(item),
                              );
                            },
                            childCount: matchingItems.length,
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 18,
                              mainAxisSpacing: 20,
                              childAspectRatio: childAspectRatio,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = matchingItems[index];
                                return ItemCard(
                                  item: item,
                                  onTap: () => _openItemDetail(context, item),
                                  onEdit: () => _openItemDetail(context, item),
                                  onDelete: () => _deleteItem(item),
                                );
                              },
                              childCount: matchingItems.length,
                            ),
                          ),
                        ),
                    ],
                  ],
                );
              }

              // Normal browsing (No Search)
              if (isListMode) {
                if (collections.isEmpty) {
                  return const EmptyState(
                    icon: Icons.folder_open_outlined,
                    title: 'No Collections Yet',
                    description: 'Click + in the top bar to create your first list.',
                  );
                }

                return CustomScrollView(
                  slivers: [
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final col = collections[index];
                          final previewItems =
                              itemsByCollection[col.id] ?? [];
                          return CollectionListTile(
                            collection: col,
                            previewItems: previewItems,
                            onTap: () => _openCollection(col),
                            onEdit: () => CollectionEditorDialog.show(
                              context,
                              collection: col,
                            ),
                            onDelete: () => _deleteCollection(col),
                          );
                        },
                        childCount: collections.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                );
              }

              // Grid View
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 20,
                        childAspectRatio: childAspectRatio,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index < collections.length) {
                            final col = collections[index];
                            final previewItems =
                                itemsByCollection[col.id] ?? [];

                            return CollectionCard(
                              collection: col,
                              previewItems: previewItems,
                              onTap: () => _openCollection(col),
                              onEdit: () => CollectionEditorDialog.show(
                                context,
                                collection: col,
                              ),
                              onDelete: () => _deleteCollection(col),
                            );
                          }

                          return AddActionCard(
                            onTap: () => CollectionEditorDialog.show(context),
                          );
                        },
                        childCount: collections.length + 1,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e'),
        ),
      ),
    );
  }

  void _openCollection(Collection col) {
    ref.read(selectedCollectionIdProvider.notifier).state = col.id;
    context.go('/collection/${col.id}');
  }

  Future<void> _deleteCollection(Collection col) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Collection',
      message:
          'Are you sure you want to permanently delete "${col.name}" and all its items? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed) {
      final repo = ref.read<CollectionRepository>(
        collectionRepositoryProvider,
      );
      await repo.deleteCollection(col.id);
    }
  }

  Future<void> _deleteItem(Item item) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Item',
      message:
          'Are you sure you want to permanently delete "${item.title}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed) {
      final repo = ref.read<ItemRepository>(itemRepositoryProvider);
      await repo.deleteItem(item.id);
    }
  }

  void _openItemDetail(BuildContext context, Item item) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Theme.of(dialogCtx).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        child: SizedBox(
          width: 540,
          height: 680,
          child: ItemDetailView(
            itemId: item.id,
            onClose: () => Navigator.of(dialogCtx).pop(),
          ),
        ),
      ),
    );
  }
}
