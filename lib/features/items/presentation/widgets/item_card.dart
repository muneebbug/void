import 'package:flutter/material.dart';
import 'package:void_app/core/theme/app_colors.dart';
import 'package:void_app/core/theme/app_typography.dart';
import 'package:void_app/features/items/domain/field_value.dart';
import 'package:void_app/features/items/domain/item.dart';
import 'package:void_app/shared/widgets/elegant_popup_menu.dart';

class ItemCard extends StatefulWidget {
  final Item item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ItemCard({
    super.key,
    required this.item,
    this.isSelected = false,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  bool _isHovered = false;
  bool _isMenuOpen = false;
  final GlobalKey _menuKey = GlobalKey();

  Future<void> _showMenu({Offset? tapPosition}) async {
    setState(() => _isMenuOpen = true);
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

    if (mounted) setState(() => _isMenuOpen = false);

    if (selected == 'edit') widget.onEdit();
    if (selected == 'delete') widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isVisible = _isHovered || _isMenuOpen;

    final ratingVal = widget.item.getField('rating');
    final double rating = ratingVal is RatingValue
        ? ratingVal.value
        : (ratingVal is NumberValue ? ratingVal.value : 0.0);

    final authorVal = widget.item.getField('author')?.toDisplayString() ?? '';
    final yearVal = widget.item.getField('year')?.toDisplayString() ??
        widget.item.getField('release_date')?.toDisplayString() ??
        '';
    final directorVal =
        widget.item.getField('director')?.toDisplayString() ?? '';
    final genreVal = widget.item.getField('genre')?.toDisplayString() ?? '';

    String subtitle = '';
    if (authorVal.isNotEmpty) {
      subtitle = authorVal;
    } else if (yearVal.isNotEmpty) {
      subtitle = yearVal.length >= 4 ? yearVal.substring(0, 4) : yearVal;
    } else if (directorVal.isNotEmpty) {
      subtitle = directorVal;
    } else if (genreVal.isNotEmpty) {
      subtitle = genreVal;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 2:3 Aspect Ratio Cover Card
            AspectRatio(
              aspectRatio: 2 / 3,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.isSelected
                        ? AppColors.primary
                        : (isVisible
                            ? (isDark
                                ? Colors.white.withValues(alpha: 0.35)
                                : AppColors.primary)
                            : (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder)),
                    width: widget.isSelected ? 1.8 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark
                            ? (_isHovered ? 0.4 : 0.18)
                            : (_isHovered ? 0.12 : 0.04),
                      ),
                      blurRadius: _isHovered ? 12 : 6,
                      offset: Offset(0, _isHovered ? 5 : 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Cover Image or Default Icon
                    if (widget.item.coverImage != null &&
                        widget.item.coverImage!.isNotEmpty)
                      Image.network(
                        widget.item.coverImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackBanner(isDark),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: isDark
                                ? const Color(0xFF1E232E)
                                : const Color(0xFFE2E8F0),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    else
                      _buildFallbackBanner(isDark),

                    // Subtle Bottom Vignette on Hover
                    if (isVisible)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.3),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Rating Star Pill
                    if (rating > 0)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 11,
                                color: AppColors.goldAccent,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Context Menu Button (always mounted, animated opacity)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: IgnorePointer(
                        ignoring: !isVisible,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: isVisible ? 1.0 : 0.0,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              key: _menuKey,
                              borderRadius: BorderRadius.circular(14),
                              onTap: _showMenu,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.more_horiz,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Typography below card (Readest style)
            Text(
              widget.item.title,
              style: AppTypography.titleSmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
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
      ),
    );
  }

  Widget _buildFallbackBanner(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF16161A) : const Color(0xFFE2E8F0),
      child: Center(
        child: Icon(
          Icons.book_outlined,
          size: 36,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
      ),
    );
  }
}

/// The dark '+' placeholder card at the end of the Readest grid
class AddActionCard extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const AddActionCard({
    super.key,
    this.label = 'Add',
    required this.onTap,
  });

  @override
  State<AddActionCard> createState() => _AddActionCardState();
}

class _AddActionCardState extends State<AddActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isDark
                      ? (_isHovered
                          ? const Color(0xFF1E1E24)
                          : const Color(0xFF111114))
                      : (_isHovered
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isHovered
                        ? (isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : AppColors.primary)
                        : (isDark
                            ? AppColors.darkBorderSubtle
                            : AppColors.lightBorder),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.add,
                    size: 32,
                    color: _isHovered
                        ? (isDark ? Colors.white : AppColors.primary)
                        : (isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Placeholder invisible spacing to align with other cards
            Text(
              '',
              style: AppTypography.titleSmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '',
              style: AppTypography.labelSmall.copyWith(
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
