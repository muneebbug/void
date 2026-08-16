import 'package:flutter/material.dart';
import 'package:void_app/core/theme/app_colors.dart';
import 'package:void_app/core/theme/app_typography.dart';
import 'package:void_app/features/items/domain/field_value.dart';
import 'package:void_app/features/items/domain/item.dart';
import 'package:void_app/shared/widgets/badge_pill.dart';

class ItemListTile extends StatelessWidget {
  final Item item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ItemListTile({
    super.key,
    required this.item,
    this.isSelected = false,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ratingVal = item.getField('rating');
    final double rating = ratingVal is RatingValue
        ? ratingVal.value
        : (ratingVal is NumberValue ? ratingVal.value : 0.0);

    final genreVal = item.getField('genre');
    final statusVal = item.getField('status') ?? item.getField('read_status');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.primary.withValues(alpha: 0.08))
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        dense: true,
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 42,
            height: 42,
            color: isDark ? const Color(0xFF1E232E) : const Color(0xFFE2E8F0),
            child: item.coverImage != null && item.coverImage!.isNotEmpty
                ? Image.network(
                    item.coverImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.insert_drive_file_outlined, size: 18),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.insert_drive_file_outlined, size: 18),
                  ),
          ),
        ),
        title: Text(
          item.title,
          style: AppTypography.titleSmall.copyWith(
            fontSize: 14,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            if (genreVal != null && genreVal.toDisplayString().isNotEmpty) ...[
              Text(
                genreVal.toDisplayString(),
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 8),
            ],
            if (statusVal != null && statusVal.toDisplayString().isNotEmpty)
              BadgePill(text: statusVal.toDisplayString()),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rating > 0) ...[
              const Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
            ],
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_vert, size: 18),
              onSelected: (val) {
                if (val == 'edit') onEdit();
                if (val == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: AppColors.error,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Delete',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
