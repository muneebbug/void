import 'package:flutter/material.dart';
import 'package:void_app/core/theme/app_colors.dart';
import 'package:void_app/core/theme/app_typography.dart';
import 'package:void_app/core/utils/schema_display_helper.dart';
import 'package:void_app/features/collections/domain/collection.dart';
import 'package:void_app/features/items/domain/item.dart';
import 'package:void_app/shared/widgets/elegant_popup_menu.dart';

class CollectionListTile extends StatefulWidget {
  final Collection collection;
  final List<Item> previewItems;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CollectionListTile({
    super.key,
    required this.collection,
    this.previewItems = const [],
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<CollectionListTile> createState() => _CollectionListTileState();
}

class _CollectionListTileState extends State<CollectionListTile> {
  final ScrollController _scrollController = ScrollController();
  bool _isHovered = false;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollArrows());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollArrows);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollArrows() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final canLeft = currentScroll > 4.0;
    final canRight = currentScroll < maxScroll - 4.0;

    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  void _scroll(double offset) {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      (_scrollController.offset + offset).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _showMenu({Offset? tapPosition}) async {
    final selected = await ElegantPopupMenu.show<String>(
      context: context,
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
    if (selected == 'edit') widget.onEdit();
    if (selected == 'delete') widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = SchemaDisplayHelper.getAccentColor(
      widget.collection.schemaId,
      isDark: isDark,
    );
    final icon = SchemaDisplayHelper.getIcon(
      widget.collection.icon,
      widget.collection.schemaId,
    );

    // Extract items with valid covers
    final itemsWithCovers = widget.previewItems
        .where((i) => i.coverImage != null && i.coverImage!.trim().isNotEmpty)
        .toList();

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
            color: _isHovered
                ? (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03))
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              // Allocate width for title on right, giving rest to cover shelf
              const titleAreaWidth = 140.0;
              final maxShelfWidth = (totalWidth - titleAreaWidth - 20)
                  .clamp(80.0, totalWidth - 60.0);

              // Single cover thumbnail size
              const coverWidth = 64.0;
              const coverHeight = 96.0;
              const coverGap = 3.5;

              final totalCoversWidth = itemsWithCovers.isEmpty
                  ? coverWidth
                  : (itemsWithCovers.length * coverWidth +
                      (itemsWithCovers.length - 1) * coverGap);

              final isShelfScrollable = totalCoversWidth > maxShelfWidth;
              final shelfDisplayWidth =
                  isShelfScrollable ? maxShelfWidth : totalCoversWidth;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Cover Shelf
                  SizedBox(
                    width: shelfDisplayWidth,
                    height: coverHeight,
                    child: itemsWithCovers.isNotEmpty
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              // Horizontal cover strip
                              ListView.separated(
                                controller: _scrollController,
                                scrollDirection: Axis.horizontal,
                                physics: const ClampingScrollPhysics(),
                                itemCount: itemsWithCovers.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: coverGap),
                                itemBuilder: (context, index) {
                                  return _buildCoverThumbnail(
                                    itemsWithCovers[index].coverImage!,
                                    isDark,
                                    coverWidth,
                                    coverHeight,
                                  );
                                },
                              ),

                              // Left Scroll Arrow (<)
                              if (isShelfScrollable && _canScrollLeft)
                                Positioned(
                                  left: 4,
                                  child: _buildArrowButton(
                                    icon: Icons.chevron_left,
                                    onTap: () => _scroll(-180),
                                  ),
                                ),

                              // Right Scroll Arrow (>)
                              if (isShelfScrollable &&
                                  (_canScrollRight || !_canScrollLeft))
                                Positioned(
                                  right: 4,
                                  child: _buildArrowButton(
                                    icon: Icons.chevron_right,
                                    onTap: () => _scroll(180),
                                  ),
                                ),
                            ],
                          )
                        : _buildEmptyCoverThumbnail(
                            icon,
                            accentColor,
                            isDark,
                            coverWidth,
                            coverHeight,
                          ),
                  ),

                  const SizedBox(width: 16),

                  // Collection Name (Readest style, vertically centered)
                  Expanded(
                    child: Text(
                      widget.collection.name,
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCoverThumbnail(
    String url,
    bool isDark,
    double width,
    double height,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E232E) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Center(
          child: Icon(
            Icons.insert_drive_file_outlined,
            size: 16,
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCoverThumbnail(
    IconData icon,
    Color accentColor,
    bool isDark,
    double width,
    double height,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      child: Center(
        child: Icon(icon, color: accentColor, size: 26),
      ),
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.8),
      shape: const CircleBorder(),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
