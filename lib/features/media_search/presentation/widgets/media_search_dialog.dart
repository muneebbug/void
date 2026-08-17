import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_app/core/theme/app_colors.dart';
import 'package:void_app/core/theme/app_typography.dart';
import 'package:void_app/features/collections/presentation/providers/collection_providers.dart';
import 'package:void_app/features/media_search/presentation/providers/media_search_provider.dart';
import 'package:void_app/features/schemas/data/builtin_schemas.dart';
import 'package:void_app/shared/widgets/empty_state.dart';
import 'package:void_app/shared/widgets/void_image.dart';

class MediaSearchDialog extends ConsumerStatefulWidget {
  final String collectionId;

  const MediaSearchDialog({super.key, required this.collectionId});

  static Future<void> show(
    BuildContext context, {
    required String collectionId,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => MediaSearchDialog(collectionId: collectionId),
    );
  }

  @override
  ConsumerState<MediaSearchDialog> createState() => _MediaSearchDialogState();
}

class _MediaSearchDialogState extends ConsumerState<MediaSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Set<String> _addedCandidateIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colDetail = ref.watch(collectionDetailProvider(widget.collectionId));
    final col = colDetail.value;
    final schemaId = col?.schemaId ?? BuiltinSchemas.moviesSchemaId;

    final searchState = ref.watch(mediaSearchProvider(schemaId));
    final searchNotifier = ref.read(mediaSearchProvider(schemaId).notifier);

    String mediaTypeLabel = 'Media';
    if (schemaId.contains('movie')) {
      mediaTypeLabel = 'Movies';
    } else if (schemaId.contains('tv')) {
      mediaTypeLabel = 'TV Shows';
    } else if (schemaId.contains('book')) {
      mediaTypeLabel = 'Books';
    }

    return Dialog(
      backgroundColor:
          isDark ? const Color(0xFF141418) : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: SizedBox(
        width: 700,
        height: 600,
        child: Column(
          children: [
            // Top Bar: Search Input and Close button
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    _getCategoryIcon(schemaId),
                    size: 19,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      textAlignVertical: TextAlignVertical.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search online $mediaTypeLabel to add to ${col?.name ?? 'list'}...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                          fontSize: 14,
                        ),
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: searchNotifier.onQueryChanged,
                    ),
                  ),
                  if (searchState.isLoading) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search Results List
            Expanded(
              child: _buildResultsView(
                context,
                searchState,
                searchNotifier,
                schemaId,
                mediaTypeLabel,
                isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView(
    BuildContext context,
    MediaSearchState searchState,
    MediaSearchNotifier searchNotifier,
    String schemaId,
    String mediaTypeLabel,
    bool isDark,
  ) {
    if (searchState.query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.travel_explore,
              size: 44,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            const SizedBox(height: 12),
            Text(
              'Search online $mediaTypeLabel database',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Type a title to fetch metadata, artwork, and rating automatically',
              style: AppTypography.bodySmall.copyWith(
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (searchState.isLoading && searchState.results.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (searchState.results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No results found',
        description:
            searchState.errorMessage ?? 'Try searching with different keywords',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: searchState.results.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      ),
      itemBuilder: (context, index) {
        final item = searchState.results[index];
        final isAdded = _addedCandidateIds.contains(item.id);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Thumbnail (2:3 Aspect Ratio)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 44,
                  height: 66,
                  child: VoidImage(
                    imageUrl: item.coverUrl,
                    width: 44,
                    height: 66,
                    fit: BoxFit.cover,
                    errorWidget: _buildCoverPlaceholder(isDark, schemaId),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.titleSmall.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Subtitle: Year, Rating, Genre / Author
                    Row(
                      children: [
                        if (item.year != null && item.year!.isNotEmpty) ...[
                          Text(
                            item.year!,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11.5,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (item.rating != null && item.rating! > 0) ...[
                          const Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: AppColors.goldAccent,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            item.rating!.toStringAsFixed(1),
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (item.genre != null && item.genre!.isNotEmpty) ...[
                          Text(
                            item.genre!,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11.5,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ] else if (item.creator != null &&
                            item.creator!.isNotEmpty) ...[
                          Text(
                            item.creator!,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11.5,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),

                    if (item.overview != null && item.overview!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.overview!,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Add Button / Added Indicator
              if (isAdded)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 14, color: AppColors.success),
                      SizedBox(width: 4),
                      Text(
                        'Added',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                )
              else
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    side: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text(
                    'Add',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () async {
                    setState(() => _addedCandidateIds.add(item.id));
                    await searchNotifier.addItem(item, widget.collectionId);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoverPlaceholder(bool isDark, String schemaId) {
    return Container(
      color: isDark ? const Color(0xFF1B1B20) : const Color(0xFFE2E8F0),
      child: Center(
        child: Icon(
          _getCategoryIcon(schemaId),
          size: 18,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String schemaId) {
    if (schemaId.contains('movies')) return Icons.movie_outlined;
    if (schemaId.contains('tv')) return Icons.tv_outlined;
    if (schemaId.contains('books')) return Icons.menu_book_outlined;
    return Icons.travel_explore;
  }
}
