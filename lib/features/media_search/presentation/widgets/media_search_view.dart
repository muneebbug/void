import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:void_app/core/theme/app_colors.dart';
import 'package:void_app/core/theme/app_typography.dart';
import 'package:void_app/features/collections/presentation/providers/collection_providers.dart';
import 'package:void_app/features/media_search/domain/media_search_result.dart';
import 'package:void_app/features/media_search/presentation/providers/media_search_provider.dart';
import 'package:void_app/features/schemas/data/builtin_schemas.dart';
import 'package:void_app/shared/widgets/badge_pill.dart';
import 'package:void_app/shared/widgets/empty_state.dart';

class MediaSearchView extends ConsumerStatefulWidget {
  final String collectionId;

  const MediaSearchView({super.key, required this.collectionId});

  @override
  ConsumerState<MediaSearchView> createState() => _MediaSearchViewState();
}

class _MediaSearchViewState extends ConsumerState<MediaSearchView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _activeSchemaId = BuiltinSchemas.moviesSchemaId;
  final Set<String> _addedCandidateIds = {};
  MediaSearchResult? _selectedCandidate;

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

    if (col != null) {
      _activeSchemaId = col.schemaId;
    }

    final searchState = ref.watch(mediaSearchProvider(_activeSchemaId));

    // Default select first item if none selected
    if (_selectedCandidate == null && searchState.results.isNotEmpty) {
      _selectedCandidate = searchState.results.first;
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
            child: Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: Text(
                    col != null ? 'Back to ${col.name}' : 'Back to List',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () =>
                      context.go('/collection/${widget.collectionId}'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Add to ${col?.name ?? 'List'}',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(width: 10),
                          BadgePill(text: _getSchemaName(_activeSchemaId)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Search live online media catalogs to import posters and metadata.',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12,
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
          const Divider(height: 1),

          // Split Screen: Search List (Left) + Live Detail Preview (Right)
          Expanded(
            child: Row(
              children: [
                // Left Search Pane (55% width)
                Expanded(
                  flex: 55,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Search Box
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            style: AppTypography.bodyMedium,
                            decoration: InputDecoration(
                              hintText: _getSearchHint(_activeSchemaId),
                              prefixIcon: const Icon(Icons.search, size: 18),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref
                                            .read(
                                              mediaSearchProvider(
                                                _activeSchemaId,
                                              ).notifier,
                                            )
                                            .onQueryChanged('');
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (val) => ref
                                .read(
                                  mediaSearchProvider(_activeSchemaId).notifier,
                                )
                                .onQueryChanged(val),
                          ),
                        ),
                        const Divider(height: 1),

                        // Search Results List
                        Expanded(
                          child: _buildResultsList(
                            context,
                            searchState,
                            widget.collectionId,
                            isDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right Live Preview Pane (45% width)
                Expanded(
                  flex: 45,
                  child: _buildPreviewPane(
                    context,
                    _selectedCandidate,
                    widget.collectionId,
                    isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSchemaName(String schemaId) {
    if (schemaId == BuiltinSchemas.moviesSchemaId) return 'Movies';
    if (schemaId == BuiltinSchemas.tvShowsSchemaId) return 'TV Shows';
    if (schemaId == BuiltinSchemas.booksSchemaId) return 'Books';
    return 'Media';
  }

  String _getSearchHint(String schemaId) {
    if (schemaId == BuiltinSchemas.moviesSchemaId) {
      return 'Search movies (e.g. Inception, Dune, Nolan)...';
    }
    if (schemaId == BuiltinSchemas.tvShowsSchemaId) {
      return 'Search TV shows (e.g. Severance, Succession)...';
    }
    if (schemaId == BuiltinSchemas.booksSchemaId) {
      return 'Search books (e.g. 1984, Atomic Habits)...';
    }
    return 'Search media online...';
  }

  Widget _buildResultsList(
    BuildContext context,
    MediaSearchState state,
    String targetCollectionId,
    bool isDark,
  ) {
    if (state.query.trim().isEmpty) {
      return const EmptyState(
        icon: Icons.travel_explore,
        title: 'Search Online',
        description: 'Type a title above to search live media catalogs.',
      );
    }

    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2.5),
            SizedBox(height: 12),
            Text('Searching live catalogs...'),
          ],
        ),
      );
    }

    if (state.results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No media found',
        description: state.errorMessage ??
            'No results matching "${state.query}". Check spelling or try different keywords.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: state.results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final candidate = state.results[index];
        final isSelected = _selectedCandidate?.id == candidate.id;
        final isAdded = _addedCandidateIds.contains(candidate.id);

        return Material(
          color: isSelected
              ? (isDark
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.08))
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            mouseCursor: SystemMouseCursors.click,
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() => _selectedCandidate = candidate);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Poster Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: candidate.coverUrl != null &&
                            candidate.coverUrl!.isNotEmpty
                        ? Image.network(
                            candidate.coverUrl!,
                            width: 36,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 36,
                              height: 50,
                              color: isDark
                                  ? const Color(0xFF1E232E)
                                  : const Color(0xFFE2E8F0),
                              child: const Icon(Icons.movie_outlined, size: 16),
                            ),
                          )
                        : Container(
                            width: 36,
                            height: 50,
                            color: isDark
                                ? const Color(0xFF1E232E)
                                : const Color(0xFFE2E8F0),
                            child: const Icon(Icons.movie_outlined, size: 16),
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Title & Metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          candidate.title,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (candidate.year != null) ...[
                              Text(
                                candidate.year!,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (candidate.rating != null &&
                                candidate.rating! > 0)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 13,
                                    color: AppColors.goldAccent,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    candidate.rating!.toStringAsFixed(1),
                                    style: AppTypography.labelSmall.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Add Quick Action
                  if (isAdded)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check,
                            size: 14,
                            color: AppColors.success,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Added',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      color: AppColors.primary,
                      tooltip: 'Add to List',
                      onPressed: () => _addCandidate(
                        candidate,
                        targetCollectionId,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewPane(
    BuildContext context,
    MediaSearchResult? candidate,
    String targetCollectionId,
    bool isDark,
  ) {
    if (candidate == null) {
      return Center(
        child: Text(
          'Select a search result to preview',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
      );
    }

    final isAdded = _addedCandidateIds.contains(candidate.id);

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        // High-res Poster Art
        if (candidate.coverUrl != null && candidate.coverUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              candidate.coverUrl!,
              height: 280,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 280,
                color:
                    isDark ? const Color(0xFF161A26) : const Color(0xFFE2E8F0),
                child: const Center(
                  child: Icon(Icons.movie_outlined, size: 48),
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),

        // Title
        Text(
          candidate.title,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 6),

        // Year · Rating · Genre Row
        Row(
          children: [
            if (candidate.year != null) ...[
              Text(
                candidate.year!,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(width: 8),
              const Text('•', style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 8),
            ],
            if (candidate.rating != null && candidate.rating! > 0) ...[
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: AppColors.goldAccent,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    candidate.rating!.toStringAsFixed(1),
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Text('•', style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 8),
            ],
            if (candidate.genre != null) BadgePill(text: candidate.genre!),
          ],
        ),
        const SizedBox(height: 18),

        // Add to List Button
        SizedBox(
          width: double.infinity,
          height: 40,
          child: isAdded
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.success),
                  ),
                  icon: const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.success,
                  ),
                  label: const Text(
                    'Added to List',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: null,
                )
              : ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Add to List',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: () => _addCandidate(
                    candidate,
                    targetCollectionId,
                  ),
                ),
        ),
        const SizedBox(height: 24),

        // Synopsis / Overview
        if (candidate.overview != null && candidate.overview!.isNotEmpty) ...[
          Text(
            'OVERVIEW',
            style: AppTypography.labelSmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            candidate.overview!,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12.5,
              height: 1.5,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Creator / Author / Network Details
        if (candidate.creator != null && candidate.creator!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                Text(
                  _activeSchemaId == BuiltinSchemas.booksSchemaId
                      ? 'Author:'
                      : 'Creator/Director:',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    candidate.creator!,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _addCandidate(
    MediaSearchResult candidate,
    String targetCollectionId,
  ) async {
    final notifier = ref.read(mediaSearchProvider(_activeSchemaId).notifier);
    final item = await notifier.addItem(candidate, targetCollectionId);
    if (item != null) {
      setState(() {
        _addedCandidateIds.add(candidate.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${item.title}" to list!'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'View List',
              onPressed: () => context.go('/collection/$targetCollectionId'),
            ),
          ),
        );
      }
    }
  }
}
