import 'package:flutter/material.dart';
import 'package:void_app/core/theme/app_colors.dart';
import 'package:void_app/core/theme/app_typography.dart';
import 'package:void_app/core/utils/schema_display_helper.dart';
import 'package:void_app/features/collections/domain/collection.dart';
import 'package:void_app/features/items/domain/item.dart';
import 'package:void_app/shared/widgets/elegant_popup_menu.dart';

class CollectionCard extends StatefulWidget {
  final Collection collection;
  final List<Item> previewItems;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CollectionCard({
    super.key,
    required this.collection,
    this.previewItems = const [],
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends State<CollectionCard> {
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
          label: 'Edit Collection',
          icon: Icons.edit_outlined,
        ),
        const ElegantMenuItem(
          value: 'delete',
          label: 'Delete Collection',
          icon: Icons.delete_outline_rounded,
          isDestructive: true,
        ),
      ],
    );
    if (mounted) {
      setState(() => _isMenuOpen = false);
    }
    if (selected == 'edit') widget.onEdit();
    if (selected == 'delete') widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isVisible = _isHovered || _isMenuOpen;

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
            // Standard 2:3 Aspect Ratio Card Box (matches ItemCard & AddActionCard)
            AspectRatio(
              aspectRatio: 2 / 3,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isVisible
                        ? (isDark
                            ? Colors.white.withValues(alpha: 0.35)
                            : AppColors.primary)
                        : (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                    width: 1,
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
                    // Collage Content (fills the entire 2:3 container)
                    _buildCollageContent(isDark),

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

                    // Context Menu Overlay Button
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

            // Collection Title
            Text(
              widget.collection.name,
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
            const SizedBox(height: 2),
            // Item Count
            Text(
              '${widget.previewItems.length} ${widget.previewItems.length == 1 ? "item" : "items"}',
              style: AppTypography.labelSmall.copyWith(
                fontSize: 11,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollageContent(bool isDark) {
    final validCovers = widget.previewItems
        .map((i) => i.coverImage)
        .where((c) => c != null && c.trim().isNotEmpty)
        .cast<String>()
        .take(4)
        .toList();

    // If 0 covers: Show clean schema category icon
    if (validCovers.isEmpty) {
      final accentColor = SchemaDisplayHelper.getAccentColor(
        widget.collection.schemaId,
        isDark: isDark,
      );
      final icon = SchemaDisplayHelper.getIcon(
        widget.collection.icon,
        widget.collection.schemaId,
      );

      return Container(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.6)
            : AppColors.lightSurface.withValues(alpha: 0.8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.14 : 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: accentColor),
          ),
        ),
      );
    }

    // If 1 cover: Full 2:3 cover fill
    if (validCovers.length == 1) {
      return _buildImageTile(validCovers[0], isDark);
    }

    // If 2 covers: 2 vertical halves
    if (validCovers.length == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildImageTile(validCovers[0], isDark)),
          const SizedBox(width: 1.5),
          Expanded(child: _buildImageTile(validCovers[1], isDark)),
        ],
      );
    }

    // If 3 covers: Left half (1 large cover) + Right half (2 stacked covers)
    if (validCovers.length == 3) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildImageTile(validCovers[0], isDark)),
          const SizedBox(width: 1.5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildImageTile(validCovers[1], isDark)),
                const SizedBox(height: 1.5),
                Expanded(child: _buildImageTile(validCovers[2], isDark)),
              ],
            ),
          ),
        ],
      );
    }

    // If 4 covers: Clean 2x2 grid completely filling the 2:3 card area
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildImageTile(validCovers[0], isDark)),
              const SizedBox(width: 1.5),
              Expanded(child: _buildImageTile(validCovers[1], isDark)),
            ],
          ),
        ),
        const SizedBox(height: 1.5),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildImageTile(validCovers[2], isDark)),
              const SizedBox(width: 1.5),
              Expanded(child: _buildImageTile(validCovers[3], isDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageTile(String imageUrl, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E232E) : const Color(0xFFE2E8F0),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildFallbackTile(isDark),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: isDark ? const Color(0xFF1E232E) : const Color(0xFFE2E8F0),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFallbackTile(bool isDark) {
    return Container(
      color: isDark
          ? const Color(0xFF1E232E)
          : const Color(0xFFE2E8F0).withValues(alpha: 0.5),
      child: Center(
        child: Icon(
          Icons.insert_drive_file_outlined,
          size: 16,
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}
