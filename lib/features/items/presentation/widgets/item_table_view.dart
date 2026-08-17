import 'package:flutter/material.dart';
import 'package:void_app/core/theme/app_colors.dart';
import 'package:void_app/core/theme/app_typography.dart';
import 'package:void_app/core/utils/date_formatter.dart';
import 'package:void_app/features/items/domain/item.dart';
import 'package:void_app/features/schemas/domain/schema.dart';

class ItemTableView extends StatelessWidget {
  final List<Item> items;
  final Schema schema;
  final String? selectedItemId;
  final ValueChanged<Item> onItemTap;
  final ValueChanged<Item> onEdit;
  final ValueChanged<Item> onDelete;

  const ItemTableView({
    super.key,
    required this.items,
    required this.schema,
    this.selectedItemId,
    required this.onItemTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Display primary fields
    final visibleFields = schema.fields.take(5).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          showCheckboxColumn: false,
          headingRowColor: WidgetStateProperty.all(
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
          ),
          headingTextStyle: AppTypography.labelSmall.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            letterSpacing: 0.5,
          ),
          dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.hovered)) {
              return isDark
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.05);
            }
            return null;
          }),
          columns: [
            const DataColumn(label: Text('TITLE')),
            for (final field in visibleFields)
              DataColumn(label: Text(field.label.toUpperCase())),
            const DataColumn(label: Text('CREATED')),
            const DataColumn(label: Text('ACTIONS')),
          ],
          rows: items.map((item) {
            final isSelected = item.id == selectedItemId;

            return DataRow(
              selected: isSelected,
              onSelectChanged: (_) => onItemTap(item),
              cells: [
                // Title Cell with small thumbnail if available
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.coverImage != null &&
                          item.coverImage!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            item.coverImage!,
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.insert_drive_file_outlined,
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          item.title,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Dynamic schema field cells
                for (final field in visibleFields)
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        item.getField(field.key)?.toDisplayString() ?? '—',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                // Created date
                DataCell(
                  Text(
                    DateFormatter.formatShortDate(item.createdAt),
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ),

                // Actions cell
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        tooltip: 'Edit',
                        onPressed: () => onEdit(item),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: AppColors.error,
                        ),
                        tooltip: 'Delete',
                        onPressed: () => onDelete(item),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
