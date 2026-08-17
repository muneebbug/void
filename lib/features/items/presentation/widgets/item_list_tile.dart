import 'package:flutter/material.dart';
import 'package:void_app/core/theme/app_colors.dart';
import 'package:void_app/core/theme/app_typography.dart';
import 'package:void_app/features/items/domain/field_value.dart';
import 'package:void_app/features/items/domain/item.dart';
import 'package:void_app/shared/widgets/elegant_popup_menu.dart';

class ItemListTile extends StatefulWidget {
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
  State<ItemListTile> createState() => _ItemListTileState();
}

class _ItemListTileState extends State<ItemListTile> {
  final GlobalKey _menuKey = GlobalKey();
  bool _isHovered = false;

  Future<void> _showMenu({Offset? tapPosition}) async {
    final selected = await ElegantPopupMenu.show<String>(
      context: context,
      anchorKey: tapPosition == null ? _menuKey : null,
      position: tapPosition,
      items: [
        const ElegantMenuItem(
          value: 'edit',
          label: 'Edit Item',
          icon: Icons.edit_outlined,
        ),
        const ElegantMenuItem(
          value: 'delete',
          label: 'Delete Item',
          icon: Icons.delete_outline_rounded,
          isDestructive: true,
        ),
      ],
    );
    if (selected == 'edit') widget.onEdit();
    if (selected == 'delete') widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ratingVal = widget.item.getField('rating');
    final double rating = ratingVal is RatingValue
        ? ratingVal.value
        : (ratingVal is NumberValue ? ratingVal.value : 0.0);

    final authorVal =
        widget.item.getField('author')?.toDisplayString() ?? '';
    final directorVal =
        widget.item.getField('director')?.toDisplayString() ?? '';
    final yearVal = widget.item.getField('year')?.toDisplayString() ??
        widget.item.getField('release_date')?.toDisplayString() ??
        '';
    final genreVal =
        widget.item.getField('genre')?.toDisplayString() ?? '';
    final descriptionVal =
        widget.item.getField('overview')?.toDisplayString() ??
            widget.item.getField('description')?.toDisplayString() ??
            widget.item.getField('notes')?.toDisplayString() ??
            '';

    final statusVal =
        widget.item.getField('status')?.toDisplayString() ??
            widget.item.getField('read_status')?.toDisplayString() ??
            '';

    // Build concise secondary subtitle (e.g. Author or Director or Genre + Year)
    String subtitle = '';
    if (authorVal.isNotEmpty) {
      subtitle = authorVal;
    } else if (directorVal.isNotEmpty) {
      subtitle = directorVal;
    } else if (genreVal.isNotEmpty && yearVal.isNotEmpty) {
      subtitle = '$genreVal • ${yearVal.length >= 4 ? yearVal.substring(0, 4) : yearVal}';
    } else if (genreVal.isNotEmpty) {
      subtitle = genreVal;
    } else if (yearVal.isNotEmpty) {
      subtitle = yearVal.length >= 4 ? yearVal.substring(0, 4) : yearVal;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onSecondaryTapDown: (details) =>
            _showMenu(tapPosition: details.globalPosition),
        child: Container(
          decoration: BoxDecoration(
            color: widget.isSelected
                ? (isDark
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.08))
                : (_isHovered
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.03))
                    : Colors.transparent),
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: 2:3 Aspect Ratio Book / Media Poster
              Container(
                width: 56,
                height: 84,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E232E)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 0.8,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.item.coverImage != null &&
                        widget.item.coverImage!.trim().isNotEmpty
                    ? Image.network(
                        widget.item.coverImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallbackCover(isDark),
                      )
                    : _buildFallbackCover(isDark),
              ),

              const SizedBox(width: 16),

              // Middle: Detailed Metadata Column (Readest style)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      widget.item.title,
                      style: AppTypography.titleSmall.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Subtitle / Author
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
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

                    // Description / Overview Snippet
                    if (descriptionVal.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        descriptionVal,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11.5,
                          height: 1.3,
                          color: isDark
                              ? AppColors.textMutedDark.withValues(alpha: 0.8)
                              : AppColors.textMutedLight.withValues(alpha: 0.85),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Rating / Status Bottom Row
                    if (rating > 0 || statusVal.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (rating > 0) ...[
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: AppColors.goldAccent,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              rating.toStringAsFixed(1),
                              style: AppTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          if (statusVal.isNotEmpty)
                            Text(
                              statusVal,
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Trailing: More Actions Button
              IconButton(
                key: _menuKey,
                icon: Icon(
                  Icons.more_horiz,
                  size: 18,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
                onPressed: () => _showMenu(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackCover(bool isDark) {
    return Center(
      child: Icon(
        Icons.insert_drive_file_outlined,
        size: 18,
        color: isDark
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.2),
      ),
    );
  }
}
