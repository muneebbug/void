import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:void_app/core/theme/app_colors.dart';
import 'package:void_app/core/theme/app_typography.dart';
import 'package:void_app/features/items/presentation/providers/item_providers.dart';
import 'package:void_app/features/search/domain/search_result.dart';
import 'package:void_app/features/search/presentation/providers/search_provider.dart';
import 'package:void_app/shared/widgets/badge_pill.dart';
import 'package:void_app/shared/widgets/empty_state.dart';

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

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

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          // Search Header & Input
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search Library',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    hintText:
                        'Search across movies, TV shows, books, genres, directors, and notes...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _controller.clear();
                              ref.read(localSearchProvider.notifier).search('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) =>
                      ref.read(localSearchProvider.notifier).search(val),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Results List
          Expanded(
            child: _buildResults(context, searchState, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(
    BuildContext context,
    LocalSearchState state,
    bool isDark,
  ) {
    if (state.query.trim().isEmpty) {
      return const EmptyState(
        icon: Icons.search,
        title: 'Search Database',
        description:
            'Type keywords above to search all local collections, media items, metadata, and tags instantly.',
      );
    }

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (state.results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No results found',
        description: 'No matching records found for "${state.query}".',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(28),
      itemCount: state.results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final res = state.results[index];

        IconData icon = Icons.insert_drive_file_outlined;
        if (res.type == SearchResultType.collection) {
          icon = Icons.folder_outlined;
        }

        return Card(
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 38,
                height: 48,
                color:
                    isDark ? const Color(0xFF1E232E) : const Color(0xFFE2E8F0),
                child: res.coverImage != null && res.coverImage!.isNotEmpty
                    ? Image.network(
                        res.coverImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(icon, size: 18),
                        ),
                      )
                    : Center(
                        child: Icon(icon, size: 18),
                      ),
              ),
            ),
            title: Text(
              res.title,
              style: AppTypography.titleSmall.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            subtitle: Text(
              res.subtitle ?? '',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11.5,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            trailing: BadgePill(text: res.type.name.toUpperCase()),
            onTap: () {
              switch (res.type) {
                case SearchResultType.collection:
                  context.go('/collection/${res.id}');
                  break;
                case SearchResultType.schema:
                  break;
                case SearchResultType.item:
                  if (res.item?.collectionId != null) {
                    ref.read(selectedItemIdProvider.notifier).state =
                        res.item!.id;
                    context.go('/collection/${res.item!.collectionId}');
                  }
                  break;
              }
            },
          ),
        );
      },
    );
  }
}
