import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:void_app/app/app_providers.dart';
import 'package:void_app/core/theme/app_colors.dart';
import 'package:void_app/core/theme/app_typography.dart';
import 'package:void_app/features/collections/domain/collection.dart';
import 'package:void_app/features/collections/presentation/widgets/collection_editor_dialog.dart';
import 'package:void_app/features/settings/domain/app_settings.dart';
import 'package:void_app/features/settings/presentation/providers/settings_provider.dart';
import 'package:void_app/shared/widgets/confirm_dialog.dart';

class ViewOptionsMenu extends ConsumerStatefulWidget {
  final Collection? currentCollection;
  final bool isAllListsPage;
  final VoidCallback onClose;

  const ViewOptionsMenu({
    super.key,
    this.currentCollection,
    required this.isAllListsPage,
    required this.onClose,
  });

  static Future<void> show({
    required BuildContext context,
    required GlobalKey anchorKey,
    Collection? currentCollection,
    required bool isAllListsPage,
  }) async {
    await showGeneralDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: 'Dismiss View Options',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (dialogContext, anim1, anim2) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        final screenHeight = MediaQuery.of(dialogContext).size.height;
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        // Dynamically compute anchor offset on every resize/rebuild
        final anchorRenderBox =
            anchorKey.currentContext?.findRenderObject() as RenderBox?;
        if (anchorRenderBox == null || !anchorRenderBox.attached) {
          return const SizedBox.shrink();
        }

        final liveOffset = anchorRenderBox.localToGlobal(Offset.zero);
        final liveSize = anchorRenderBox.size;

        const menuWidth = 224.0;
        final right = (screenWidth - (liveOffset.dx + liveSize.width)).clamp(
          8.0,
          screenWidth - menuWidth - 8.0,
        );
        final top = (liveOffset.dy + liveSize.height + 6.0).clamp(
          8.0,
          screenHeight - 50.0,
        );

        return Stack(
          children: [
            Positioned(
              top: top,
              right: right,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: menuWidth,
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
                  child: ViewOptionsMenu(
                    currentCollection: currentCollection,
                    isAllListsPage: isAllListsPage,
                    onClose: () {
                      if (Navigator.of(dialogContext, rootNavigator: true).canPop()) {
                        Navigator.of(dialogContext, rootNavigator: true).pop();
                      }
                    },
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

  @override
  ConsumerState<ViewOptionsMenu> createState() => _ViewOptionsMenuState();
}

class _ViewOptionsMenuState extends ConsumerState<ViewOptionsMenu> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final isList = settings.defaultViewMode == ItemViewMode.list;
    final isGrid = !isList;
    final isAutoColumns = settings.gridColumns == null;
    final screenWidth = MediaQuery.of(context).size.width;
    final autoColumns = (screenWidth / 165).floor().clamp(3, 12);
    final currentColumns = settings.gridColumns ?? autoColumns;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. List Option
          _MenuItemRow(
            icon: isList ? Icons.check : null,
            label: 'List',
            isSelected: isList,
            isDark: isDark,
            onTap: () {
              ref
                  .read(settingsProvider.notifier)
                  .setViewMode(ItemViewMode.list);
            },
          ),

          // 2. Grid Option
          _MenuItemRow(
            icon: isGrid ? Icons.check : null,
            label: 'Grid',
            isSelected: isGrid,
            isDark: isDark,
            onTap: () {
              ref
                  .read(settingsProvider.notifier)
                  .setViewMode(ItemViewMode.grid);
            },
          ),

          const _MenuDivider(),

          // 3. Columns Header & Controls (Disabled when List view is selected)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
            child: Text(
              'Columns',
              style: AppTypography.labelSmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isList
                    ? (isDark
                        ? const Color(0xFF52525B)
                        : const Color(0xFFA1A1AA))
                    : (isDark
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF6B7280)),
              ),
            ),
          ),

          Opacity(
            opacity: isList ? 0.35 : 1.0,
            child: IgnorePointer(
              ignoring: isList,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
                child: Row(
                  children: [
                    // 'Auto' Pill Button
                    InkWell(
                      mouseCursor: SystemMouseCursors.click,
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        ref
                            .read(settingsProvider.notifier)
                            .setGridColumns(null);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isAutoColumns
                              ? (isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.08))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isAutoColumns
                                ? (isDark
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : Colors.black.withValues(alpha: 0.14))
                                : (isDark
                                    ? const Color(0xFF27272A)
                                    : const Color(0xFFE5E7EB)),
                          ),
                        ),
                        child: Text(
                          'Auto',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                            fontWeight: isAutoColumns
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isAutoColumns
                                ? (isDark ? Colors.white : Colors.black87)
                                : (isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Current Column Count Display
                    Text(
                      '$currentColumns',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Minus Button (Minimum 3 columns)
                    _CircleStepButton(
                      icon: Icons.remove,
                      isDark: isDark,
                      isEnabled: currentColumns > 3,
                      onTap: () {
                        final next = (currentColumns - 1).clamp(3, 12);
                        ref
                            .read(settingsProvider.notifier)
                            .setGridColumns(next);
                      },
                    ),

                    const SizedBox(width: 4),

                    // Plus Button (Maximum 12 columns)
                    _CircleStepButton(
                      icon: Icons.add,
                      isDark: isDark,
                      isEnabled: currentColumns < 12,
                      onTap: () {
                        final next = (currentColumns + 1).clamp(3, 12);
                        ref
                            .read(settingsProvider.notifier)
                            .setGridColumns(next);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Collection Actions (Only shown on Collection Page, NOT on Homepage)
          if (!widget.isAllListsPage && widget.currentCollection != null) ...[
            const _MenuDivider(),

            _MenuItemRow(
              icon: Icons.edit_outlined,
              label: 'Edit List',
              isDark: isDark,
              onTap: () {
                widget.onClose();
                CollectionEditorDialog.show(
                  context,
                  collection: widget.currentCollection,
                );
              },
            ),

            _MenuItemRow(
              icon: Icons.delete_outline_rounded,
              label: 'Delete List',
              isDestructive: true,
              isDark: isDark,
              onTap: () async {
                widget.onClose();
                final col = widget.currentCollection!;
                final confirmed = await ConfirmDialog.show(
                  context,
                  title: 'Delete List',
                  message:
                      'Are you sure you want to permanently delete "${col.name}" and all its media items? This cannot be undone.',
                  confirmLabel: 'Delete',
                  isDestructive: true,
                );
                if (confirmed) {
                  final repo = ref.read(collectionRepositoryProvider);
                  await repo.deleteCollection(col.id);
                  if (context.mounted) {
                    context.go('/');
                  }
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuItemRow extends StatefulWidget {
  final IconData? icon;
  final String label;
  final bool isSelected;
  final bool isDestructive;
  final bool isDark;
  final VoidCallback onTap;

  const _MenuItemRow({
    this.icon,
    required this.label,
    this.isSelected = false,
    this.isDestructive = false,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_MenuItemRow> createState() => _MenuItemRowState();
}

class _MenuItemRowState extends State<_MenuItemRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color textColor;
    if (widget.isDestructive) {
      textColor = AppColors.error;
    } else if (widget.isSelected) {
      textColor = widget.isDark ? Colors.white : Colors.black87;
    } else {
      textColor = widget.isDark
          ? const Color(0xFFD4D4D8)
          : const Color(0xFF3F3F46);
    }

    final hoverBg = widget.isDestructive
        ? AppColors.error.withValues(alpha: 0.12)
        : (widget.isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.05));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _isHovered ? hoverBg : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: widget.icon != null
                    ? Icon(
                        widget.icon,
                        size: 14,
                        color: widget.isDestructive
                            ? AppColors.error
                            : (widget.isDark ? Colors.white : Colors.black87),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 13,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleStepButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final bool isEnabled;
  final VoidCallback onTap;

  const _CircleStepButton({
    required this.icon,
    required this.isDark,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06),
      shape: const CircleBorder(),
      child: InkWell(
        mouseCursor:
            isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        customBorder: const CircleBorder(),
        onTap: isEnabled ? onTap : null,
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 13,
            color: isEnabled
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? const Color(0xFF52525B) : const Color(0xFFA1A1AA)),
          ),
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
    );
  }
}
