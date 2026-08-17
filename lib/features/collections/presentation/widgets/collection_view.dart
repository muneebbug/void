import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:void_app/app/app_providers.dart';
import 'package:void_app/core/theme/app_colors.dart';
import 'package:void_app/core/theme/app_typography.dart';
import 'package:void_app/features/collections/domain/collection.dart';
import 'package:void_app/features/collections/presentation/providers/collection_providers.dart';
import 'package:void_app/features/items/data/item_repository.dart';
import 'package:void_app/features/items/domain/item.dart';
import 'package:void_app/features/items/presentation/providers/item_providers.dart';
import 'package:void_app/features/items/presentation/widgets/item_card.dart';
import 'package:void_app/features/items/presentation/widgets/item_detail_view.dart';
import 'package:void_app/features/items/presentation/widgets/item_list_tile.dart';
import 'package:void_app/features/media_search/presentation/widgets/media_search_dialog.dart';
import 'package:void_app/features/search/presentation/providers/search_provider.dart';
import 'package:void_app/features/settings/domain/app_settings.dart';
import 'package:void_app/features/settings/presentation/providers/settings_provider.dart';
import 'package:void_app/shared/widgets/confirm_dialog.dart';
import 'package:void_app/shared/widgets/empty_state.dart';

class CollectionView extends ConsumerStatefulWidget {
  final String collectionId;

  const CollectionView({super.key, required this.collectionId});

  @override
  ConsumerState<CollectionView> createState() => _CollectionViewState();
}

class _CollectionViewState extends ConsumerState<CollectionView> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final collectionAsync =
        ref.watch(collectionDetailProvider(widget.collectionId));
    final itemsAsync =
        ref.watch(collectionItemsProvider(widget.collectionId));
    final searchQuery =
        ref.watch(globalSearchQueryProvider).trim().toLowerCase();
    final settings = ref.watch(settingsProvider);
    final isListMode = settings.defaultViewMode == ItemViewMode.list;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: collectionAsync.when(
        data: (collection) {
          if (collection == null) {
            return const EmptyState(
              icon: Icons.folder_off_outlined,
              title: 'Collection Not Found',
              description: 'This collection may have been deleted.',
            );
          }

          return Column(
            children: [
              // Readest Breadcrumb Header (All > Collection Name)
              _buildBreadcrumbHeader(context, collection, isDark),

              // Items View (Grid or List)
              Expanded(
                child: itemsAsync.when(
                  data: (items) {
                    final isSearching = searchQuery.isNotEmpty;
                    final filteredItems = isSearching
                        ? items
                            .where(
                              (item) => item.title
                                  .toLowerCase()
                                  .contains(searchQuery),
                            )
                            .toList()
                        : items;

                    if (isSearching && filteredItems.isEmpty) {
                      return EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No Matching Items',
                        description:
                            'No items in "${collection.name}" match "$searchQuery".',
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = settings.gridColumns ??
                            (width / 165).floor().clamp(3, 12);

                        // Exact dynamic aspect ratio to fit 2:3 card + 50px text
                        const horizontalPadding = 48.0;
                        final totalSpacing = (crossAxisCount - 1) * 18.0;
                        final columnWidth =
                            (width - horizontalPadding - totalSpacing) /
                                crossAxisCount;
                        final boxHeight = columnWidth * 1.5;
                        const textSectionHeight = 50.0;
                        final totalCardHeight = boxHeight + textSectionHeight;
                        final childAspectRatio =
                            (columnWidth / totalCardHeight).clamp(0.35, 0.75);

                        if (isListMode) {
                          if (filteredItems.isEmpty && !isSearching) {
                            return const EmptyState(
                              icon: Icons.bookmark_border_rounded,
                              title: 'No Items in Collection',
                              description:
                                  'Click + in the top bar to add items to this collection.',
                            );
                          }

                          return CustomScrollView(
                            slivers: [
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final item = filteredItems[index];
                                    return ItemListTile(
                                      item: item,
                                      onTap: () =>
                                          _openItemDetail(context, item),
                                      onEdit: () =>
                                          _openItemDetail(context, item),
                                      onDelete: () => _deleteItem(item),
                                    );
                                  },
                                  childCount: filteredItems.length,
                                ),
                              ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 40),
                              ),
                            ],
                          );
                        }

                        // Grid View
                        return CustomScrollView(
                          slivers: [
                            SliverPadding(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 8, 24, 40),
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
                                    if (index < filteredItems.length) {
                                      final item = filteredItems[index];
                                      return ItemCard(
                                        item: item,
                                        onTap: () =>
                                            _openItemDetail(context, item),
                                        onEdit: () =>
                                            _openItemDetail(context, item),
                                        onDelete: () => _deleteItem(item),
                                      );
                                    }

                                    // '+' Add Action Card -> Opens Media Search Dialog
                                    return AddActionCard(
                                      onTap: () => MediaSearchDialog.show(
                                        context,
                                        collectionId: collection.id,
                                      ),
                                    );
                                  },
                                  childCount: isSearching
                                      ? filteredItems.length
                                      : items.length + 1,
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
                    child: Text('Error loading items: $e'),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (e, _) => Center(
          child: Text('Error loading collection: $e'),
        ),
      ),
    );
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

  Widget _buildBreadcrumbHeader(
    BuildContext context,
    Collection collection,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Row(
        children: [
          // 'All' link back to home
          InkWell(
            mouseCursor: SystemMouseCursors.click,
            onTap: () => context.go('/'),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'All',
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // '>' Chevron
          Icon(
            Icons.chevron_right,
            size: 16,
            color: isDark
                ? AppColors.textMutedDark
                : AppColors.textMutedLight,
          ),
          const SizedBox(width: 4),

          // Active Collection Name
          Text(
            collection.name,
            style: AppTypography.titleMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
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
