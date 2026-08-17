import 'package:flutter/material.dart';
import 'package:void_app/core/theme/app_colors.dart';
import 'package:void_app/core/theme/app_typography.dart';

class ElegantMenuItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final bool isDestructive;
  final bool isSelected;

  const ElegantMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.isDestructive = false,
    this.isSelected = false,
  });
}

class ElegantPopupMenu {
  static Future<T?> show<T>({
    required BuildContext context,
    GlobalKey? anchorKey,
    Offset? position,
    required List<ElegantMenuItem<T>> items,
    double menuWidth = 180.0,
  }) async {
    return showGeneralDialog<T>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Popup',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (dialogContext, anim1, anim2) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        final screenHeight = MediaQuery.of(dialogContext).size.height;
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        final estimatedHeight = items.length * 36.0 + 16.0;

        double left;
        double top;

        if (position != null) {
          // Precise cursor-based positioning (Right Click Context Menu)
          if (position.dx + menuWidth > screenWidth - 12.0) {
            left = (position.dx - menuWidth)
                .clamp(8.0, screenWidth - menuWidth - 8.0);
          } else {
            left = position.dx.clamp(8.0, screenWidth - menuWidth - 8.0);
          }

          if (position.dy + estimatedHeight > screenHeight - 12.0) {
            top = (position.dy - estimatedHeight)
                .clamp(8.0, screenHeight - estimatedHeight - 8.0);
          } else {
            top = position.dy
                .clamp(8.0, screenHeight - estimatedHeight - 8.0);
          }
        } else if (anchorKey != null) {
          // Anchor widget-based positioning (Button Click)
          final anchorRenderBox =
              anchorKey.currentContext?.findRenderObject() as RenderBox?;
          if (anchorRenderBox == null || !anchorRenderBox.attached) {
            return const SizedBox.shrink();
          }

          final liveOffset = anchorRenderBox.localToGlobal(Offset.zero);
          final liveSize = anchorRenderBox.size;

          left = (liveOffset.dx + liveSize.width - menuWidth).clamp(
            8.0,
            screenWidth - menuWidth - 8.0,
          );

          if (liveOffset.dy + liveSize.height + 4.0 + estimatedHeight >
              screenHeight - 16.0) {
            top = (liveOffset.dy - estimatedHeight - 4.0).clamp(
              8.0,
              screenHeight,
            );
          } else {
            top = liveOffset.dy + liveSize.height + 4.0;
          }
        } else {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: menuWidth,
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF141416)
                        : const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2C2C30)
                          : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.5 : 0.12,
                        ),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: items.map((item) {
                      return _ElegantMenuItemWidget(
                        item: item,
                        isDark: isDark,
                        onTap: () {
                          if (Navigator.of(dialogContext, rootNavigator: true)
                              .canPop()) {
                            Navigator.of(dialogContext, rootNavigator: true)
                                .pop(item.value);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }
}

class _ElegantMenuItemWidget<T> extends StatefulWidget {
  final ElegantMenuItem<T> item;
  final bool isDark;
  final VoidCallback onTap;

  const _ElegantMenuItemWidget({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ElegantMenuItemWidget<T>> createState() =>
      _ElegantMenuItemWidgetState<T>();
}

class _ElegantMenuItemWidgetState<T> extends State<_ElegantMenuItemWidget<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDestructive = item.isDestructive;

    Color textColor;
    if (isDestructive) {
      textColor = AppColors.error;
    } else if (widget.isDark) {
      textColor = AppColors.textPrimaryDark;
    } else {
      textColor = AppColors.textPrimaryLight;
    }

    final hoverColor = isDestructive
        ? AppColors.error.withValues(alpha: 0.1)
        : (widget.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered ? hoverColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: 16,
                  color: isDestructive
                      ? AppColors.error
                      : (widget.isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  item.label,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 13,
                    fontWeight:
                        item.isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.isSelected) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.check,
                  size: 15,
                  color: widget.isDark ? Colors.white : Colors.black87,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
