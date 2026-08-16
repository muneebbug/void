import 'package:flutter/material.dart';
import 'package:void_app/core/theme/app_colors.dart';
import 'package:void_app/core/theme/app_typography.dart';
import 'package:void_app/features/collections/domain/collection.dart';
import 'package:void_app/features/items/domain/item.dart';

class CollectionCard extends StatefulWidget {
  final Collection collection;
  final List<Item> previewItems;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  const CollectionCard({
    super.key,
    required this.collection,
    this.previewItems = const [],
    required this.onTap,
    required this.onEdit,
    required this.onExport,
    required this.onDelete,
  });

  @override
  State<CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends State<CollectionCard> {
  bool _isHovered = false;
  bool _isMenuOpen = false;

  void _showContextMenu(BuildContext context, Offset position) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final localPosition = overlay.globalToLocal(position);

    setState(() => _isMenuOpen = true);
    final selected = await showMenu<String>(
      context: context,
      popUpAnimationStyle: AnimationStyle.noAnimation,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(localPosition.dx, localPosition.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 15),
              SizedBox(width: 8),
              Text('Edit Collection'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.import_export, size: 15),
              SizedBox(width: 8),
              Text('Export JSON / CSV'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                size: 15,
                color: AppColors.error,
              ),
              SizedBox(width: 8),
              Text(
                'Delete Collection',
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
    );

    if (mounted) setState(() => _isMenuOpen = false);

    if (selected == 'edit') widget.onEdit();
    if (selected == 'export') widget.onExport();
    if (selected == 'delete') widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = widget.collection.itemCount;
    final isVisible = _isHovered || _isMenuOpen;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onSecondaryTapDown: (details) =>
            _showContextMenu(context, details.globalPosition),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 2:3 Aspect Ratio Card with 2x2 Collage
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
                  boxShadow: isVisible
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Collage Content
                    _buildCollageContent(isDark),

                    // Context Menu Overlay Button (always in tree to avoid unmounting on hover exit)
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
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                shape: BoxShape.circle,
                              ),
                              child: PopupMenuButton<String>(
                                popUpAnimationStyle: AnimationStyle.noAnimation,
                                padding: EdgeInsets.zero,
                                iconSize: 14,
                                icon: const Icon(
                                  Icons.more_horiz,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                onOpened: () =>
                                    setState(() => _isMenuOpen = true),
                                onCanceled: () =>
                                    setState(() => _isMenuOpen = false),
                                onSelected: (val) {
                                  setState(() => _isMenuOpen = false);
                                  if (val == 'edit') widget.onEdit();
                                  if (val == 'export') widget.onExport();
                                  if (val == 'delete') widget.onDelete();
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 15),
                                        SizedBox(width: 8),
                                        Text('Edit Collection'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'export',
                                    child: Row(
                                      children: [
                                        Icon(Icons.import_export, size: 15),
                                        SizedBox(width: 8),
                                        Text('Export JSON / CSV'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          size: 15,
                                          color: AppColors.error,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete Collection',
                                          style:
                                              TextStyle(color: AppColors.error),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
            Text(
              count == 1 ? '1 item' : '$count items',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11.5,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
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
        .where((i) => i.coverImage != null && i.coverImage!.isNotEmpty)
        .map((i) => i.coverImage!)
        .toList();

    // Always 4-split (2x2 grid) filled based on items in the list
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildCoverTile(validCovers, 0, isDark)),
              Container(
                width: 1,
                color: isDark ? const Color(0xFF1F1F24) : const Color(0xFFE2E8F0),
              ),
              Expanded(child: _buildCoverTile(validCovers, 1, isDark)),
            ],
          ),
        ),
        Container(
          height: 1,
          color: isDark ? const Color(0xFF1F1F24) : const Color(0xFFE2E8F0),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildCoverTile(validCovers, 2, isDark)),
              Container(
                width: 1,
                color: isDark ? const Color(0xFF1F1F24) : const Color(0xFFE2E8F0),
              ),
              Expanded(child: _buildCoverTile(validCovers, 3, isDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoverTile(List<String> covers, int index, bool isDark) {
    if (index < covers.length) {
      return Image.network(
        covers[index],
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholderTile(isDark),
      );
    }
    return _buildPlaceholderTile(isDark);
  }

  Widget _buildPlaceholderTile(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF141418) : const Color(0xFFF1F5F9),
      child: Center(
        child: Icon(
          _getCategoryIcon(widget.collection.schemaId),
          size: 16,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
    );
  }



  IconData _getCategoryIcon(String schemaId) {
    if (schemaId.contains('movies')) return Icons.movie_outlined;
    if (schemaId.contains('tv')) return Icons.tv_outlined;
    if (schemaId.contains('books')) return Icons.menu_book_outlined;
    return Icons.folder_open_outlined;
  }
}
