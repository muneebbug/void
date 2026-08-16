import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_app/app/app_providers.dart';
import 'package:void_app/core/theme/app_colors.dart';
import 'package:void_app/core/theme/app_typography.dart';
import 'package:void_app/core/utils/id_generator.dart';
import 'package:void_app/features/items/domain/field_value.dart';
import 'package:void_app/features/items/domain/item.dart';
import 'package:void_app/features/items/presentation/providers/item_providers.dart';
import 'package:void_app/features/items/presentation/widgets/item_editor_dialog.dart';
import 'package:void_app/features/schemas/presentation/providers/schema_providers.dart';
import 'package:void_app/shared/widgets/badge_pill.dart';
import 'package:void_app/shared/widgets/confirm_dialog.dart';

class ItemDetailView extends ConsumerStatefulWidget {
  final String itemId;
  final VoidCallback? onClose;

  const ItemDetailView({
    super.key,
    required this.itemId,
    this.onClose,
  });

  @override
  ConsumerState<ItemDetailView> createState() => _ItemDetailViewState();
}

class _ItemDetailViewState extends ConsumerState<ItemDetailView> {
  final TextEditingController _subItemInputController = TextEditingController();

  @override
  void dispose() {
    _subItemInputController.dispose();
    super.dispose();
  }

  Future<void> _addSubItem(Item parentItem) async {
    final title = _subItemInputController.text.trim();
    if (title.isEmpty) return;

    final sub = Item(
      id: IdGenerator.generate(),
      collectionId: parentItem.collectionId,
      schemaId: parentItem.schemaId,
      parentItemId: parentItem.id,
      title: title,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final repo = ref.read(itemRepositoryProvider);
    await repo.createItem(sub);
    _subItemInputController.clear();
  }

  Future<void> _deleteSubItem(String subItemId) async {
    final repo = ref.read(itemRepositoryProvider);
    await repo.permanentlyDeleteItem(subItemId);
  }

  void _dismiss(BuildContext context) {
    ref.read(selectedItemIdProvider.notifier).state = null;
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemAsync = ref.watch(itemDetailProvider(widget.itemId));

    return itemAsync.when(
      data: (item) {
        if (item == null) {
          return const Center(child: Text('Item not found or deleted'));
        }

        final schemaAsync = ref.watch(schemaDetailProvider(item.schemaId));
        final schema = schemaAsync.asData?.value;
        final schemaName = schema?.name ?? 'Item';

        final ratingVal = item.getField('rating');
        final double rating = ratingVal is RatingValue
            ? ratingVal.value
            : (ratingVal is NumberValue ? ratingVal.value : 0.0);

        final author = item.getField('author')?.toDisplayString() ?? '';
        final genre = item.getField('genre')?.toDisplayString() ?? '';
        final year = item.getField('year')?.toDisplayString() ??
            item.getField('release_date')?.toDisplayString() ??
            '';
        final cleanYear = year.length >= 4 ? year.substring(0, 4) : year;
        final director = item.getField('director')?.toDisplayString() ?? '';

        final overview = item.getField('overview')?.toDisplayString() ??
            item.getField('description')?.toDisplayString() ??
            item.getField('notes')?.toDisplayString() ??
            '';

        // Build header subtitle
        final List<String> subtitleParts = [];
        if (author.isNotEmpty) subtitleParts.add(author);
        if (director.isNotEmpty && author.isEmpty) subtitleParts.add(director);
        if (genre.isNotEmpty) subtitleParts.add(genre);
        if (cleanYear.isNotEmpty) subtitleParts.add(cleanYear);
        final headerSubtitle = subtitleParts.join(' • ');

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Top Bar with centered title and right close button (Readest style)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
                child: Row(
                  children: [
                    const SizedBox(width: 32),
                    Expanded(
                      child: Center(
                        child: Text(
                          '$schemaName Details',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: 'Close',
                      onPressed: () => _dismiss(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Hero Section: Cover on Left, Title + Subtitle + Actions on Right
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover Card (Aspect Ratio 2:3, fully visible)
                        Container(
                          width: 110,
                          height: 165,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCard
                                : AppColors.lightCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: item.coverImage != null &&
                                  item.coverImage!.isNotEmpty
                              ? Image.network(
                                  item.coverImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildFallbackCover(isDark),
                                )
                              : _buildFallbackCover(isDark),
                        ),
                        const SizedBox(width: 16),

                        // Title, Subtitle & Action buttons
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: AppTypography.titleLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              if (headerSubtitle.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  headerSubtitle,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 12.5,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                              if (rating > 0) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: AppColors.goldAccent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${rating.toStringAsFixed(1)} / 10',
                                      style: AppTypography.labelSmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11.5,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 14),

                              // Action Buttons (Edit, Delete)
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                    ),
                                    tooltip: 'Edit Item',
                                    onPressed: () => ItemEditorDialog.show(
                                      context,
                                      item: item,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: AppColors.error,
                                    ),
                                    tooltip: 'Delete Item',
                                    onPressed: () async {
                                      final confirmed =
                                          await ConfirmDialog.show(
                                        context,
                                        title: 'Delete Item',
                                        message:
                                            'Are you sure you want to permanently delete "${item.title}"? This action cannot be undone.',
                                        confirmLabel: 'Delete',
                                        isDestructive: true,
                                      );
                                      if (confirmed) {
                                        final repo =
                                            ref.read(itemRepositoryProvider);
                                        await repo.deleteItem(item.id);
                                        if (context.mounted) {
                                          _dismiss(context);
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Overview / Synopsis
                    if (overview.isNotEmpty) ...[
                      Text(
                        'OVERVIEW',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        overview,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12.5,
                          height: 1.55,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],

                    // Metadata Section
                    schemaAsync.when(
                      data: (schemaData) {
                        if (schemaData == null || schemaData.fields.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        // Filter fields with actual values
                        final populatedFields = schemaData.fields.where((f) {
                          if (f.key == 'overview' ||
                              f.key == 'description' ||
                              f.key == 'title' ||
                              f.key == 'cover_image') {
                            return false;
                          }
                          final val = item.getField(f.key);
                          return val != null && val.isNotEmpty;
                        }).toList();

                        if (populatedFields.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'METADATA',
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCard
                                    : AppColors.lightCard,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                ),
                              ),
                              child: Column(
                                children: populatedFields.map((field) {
                                  final val = item.getField(field.key);
                                  if (val == null || val.isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 9,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 110,
                                          child: Text(
                                            field.label,
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w500,
                                              color: isDark
                                                  ? AppColors.textMutedDark
                                                  : AppColors.textMutedLight,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: _renderFieldValue(
                                            field.key,
                                            val,
                                            isDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 22),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    // Sub-items Section
                    Text(
                      'SUB-ITEMS / NOTES (${item.subItems.length})',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _subItemInputController,
                            style: AppTypography.bodySmall,
                            decoration: const InputDecoration(
                              hintText: 'Add note or episode...',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                            ),
                            onSubmitted: (_) => _addSubItem(item),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          icon: const Icon(Icons.add, size: 16),
                          onPressed: () => _addSubItem(item),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (item.subItems.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color:
                              isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: item.subItems.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final sub = item.subItems[idx];
                            return ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.subdirectory_arrow_right,
                                size: 16,
                              ),
                              title: Text(
                                sub.title,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 14),
                                onPressed: () => _deleteSubItem(sub.id),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (e, _) => Center(
        child: Text('Error loading item: $e'),
      ),
    );
  }

  Widget _buildFallbackCover(bool isDark) {
    return Center(
      child: Icon(
        Icons.insert_drive_file_outlined,
        size: 32,
        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
      ),
    );
  }

  Widget _renderFieldValue(String key, FieldValue val, bool isDark) {
    if (val is MultiSelectValue) {
      return Wrap(
        spacing: 6,
        runSpacing: 4,
        children: val.value.map((e) => BadgePill(text: e)).toList(),
      );
    }

    if (val is SelectValue) {
      return BadgePill(text: val.toDisplayString());
    }

    if (val is RatingValue) {
      final rounded = (val.value * 10).round() / 10.0;
      final formatted =
          rounded % 1 == 0 ? rounded.toInt().toString() : rounded.toStringAsFixed(1);
      final maxScale = val.value > 5.0 ? 10 : 5;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 15,
            color: AppColors.goldAccent,
          ),
          const SizedBox(width: 4),
          Text(
            '$formatted / $maxScale',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      );
    }

    return Text(
      val.toDisplayString(),
      style: AppTypography.bodySmall.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
    );
  }
}
