import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:void_app/core/theme/app_colors.dart';
import 'package:void_app/core/theme/app_typography.dart';
import 'package:void_app/features/collections/presentation/providers/collection_providers.dart';
import 'package:void_app/features/collections/presentation/widgets/collection_editor_dialog.dart';
import 'package:void_app/features/import_export/presentation/widgets/import_export_dialog.dart';
import 'package:void_app/features/items/presentation/providers/item_providers.dart';
import 'package:void_app/features/media_search/presentation/widgets/media_search_dialog.dart';
import 'package:void_app/features/search/presentation/providers/search_provider.dart';
import 'package:void_app/features/settings/presentation/providers/settings_provider.dart';
import 'package:void_app/shared/widgets/command_palette.dart';
import 'package:window_manager/window_manager.dart';

class DesktopLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String currentRoute;

  const DesktopLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  ConsumerState<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends ConsumerState<DesktopLayout>
    with WindowListener {
  final FocusNode _focusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      windowManager.addListener(this);
      _checkMaximized();
    }
  }

  @override
  void didUpdateWidget(DesktopLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentRoute != oldWidget.currentRoute) {
      if (_searchController.text.isNotEmpty) {
        _searchController.clear();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(globalSearchQueryProvider.notifier).state = '';
          }
        });
      }
    }
  }

  Future<void> _checkMaximized() async {
    try {
      final max = await windowManager.isMaximized();
      if (mounted) setState(() => _isMaximized = max);
    } catch (_) {}
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  @override
  void dispose() {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      windowManager.removeListener(this);
    }
    _focusNode.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isControlOrMeta = HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;

      // Ctrl/Cmd + K -> Command Palette
      if (isControlOrMeta && event.logicalKey == LogicalKeyboardKey.keyK) {
        CommandPalette.show(context);
      }

      // Ctrl/Cmd + N -> New Item or Collection
      if (isControlOrMeta && event.logicalKey == LogicalKeyboardKey.keyN) {
        final activeCol = ref.read(selectedCollectionProvider);
        if (activeCol != null) {
          MediaSearchDialog.show(context, collectionId: activeCol.id);
        } else {
          CollectionEditorDialog.show(context);
        }
      }

      // Ctrl/Cmd + F -> Focus In-Place Search
      if (isControlOrMeta && event.logicalKey == LogicalKeyboardKey.keyF) {
        _searchFocusNode.requestFocus();
        _searchController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _searchController.text.length,
        );
      }

      // Escape -> Clear & Unfocus Search
      if (event.logicalKey == LogicalKeyboardKey.escape &&
          _searchFocusNode.hasFocus) {
        _searchController.clear();
        ref.read(globalSearchQueryProvider.notifier).state = '';
        _searchFocusNode.unfocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Column(
          children: [
            // Custom Readest Frameless Top Titlebar
            _buildReadestTopBar(context, isDark),

            // Main Content Area (Edge to Edge)
            Expanded(
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadestTopBar(
    BuildContext context,
    bool isDark,
  ) {
    final isDesktopPlatform = !kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

    final barContent = Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      ),
      child: Row(
        children: [
          // Flexible Search Pill with integrated Quick Actions (Readest style)
          Expanded(
            child: _buildSearchAndQuickActionPill(context, isDark),
          ),

          const SizedBox(width: 12),

          // Right Cluster: '...' More Menu, View Mode, Window Controls
          _buildRightCluster(context, isDark, isDesktopPlatform),
        ],
      ),
    );

    if (isDesktopPlatform) {
      return DragToMoveArea(child: barContent);
    }
    return barContent;
  }

  Widget _buildSearchAndQuickActionPill(
    BuildContext context,
    bool isDark,
  ) {
    String searchLabel = 'Search library...';

    if (widget.currentRoute.startsWith('/collection/')) {
      final segments = widget.currentRoute.split('/');
      final colId = segments.length > 2 ? segments[2] : null;
      if (colId != null) {
        final colAsync = ref.watch(collectionDetailProvider(colId));
        final itemsAsync = ref.watch(collectionItemsProvider(colId));
        final count = itemsAsync.value?.length ?? 0;
        final colName = colAsync.value?.name;

        if (count == 1) {
          searchLabel = 'Search in 1 item...';
        } else if (count > 0) {
          searchLabel = 'Search in $count items...';
        } else if (colName != null && colName.isNotEmpty) {
          searchLabel = 'Search in $colName...';
        } else {
          searchLabel = 'Search in collection...';
        }
      }
    } else {
      final allItemsAsync = ref.watch(allItemsStreamProvider);
      final totalItems = allItemsAsync.value?.length ?? 0;
      if (totalItems == 1) {
        searchLabel = 'Search in 1 item...';
      } else if (totalItems > 0) {
        searchLabel = 'Search in $totalItems items...';
      } else {
        searchLabel = 'Search library...';
      }
    }

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16161A) : AppColors.lightCardHover,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Search Icon
          Icon(
            Icons.search,
            size: 15,
            color: isDark
                ? AppColors.textMutedDark
                : AppColors.textMutedLight,
          ),
          const SizedBox(width: 8),

          // Flexible Search Input Field
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 12,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              cursorColor: isDark ? AppColors.primary : AppColors.primaryLight,
              cursorHeight: 13,
              cursorWidth: 1.5,
              decoration: InputDecoration(
                hintText: searchLabel,
                hintStyle: AppTypography.bodySmall.copyWith(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
                isDense: true,
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 7),
              ),
              onChanged: (val) {
                ref.read(globalSearchQueryProvider.notifier).state = val;
                setState(() {});
              },
            ),
          ),

          // Clear Button
          if (_searchController.text.isNotEmpty) ...[
            InkWell(
              onTap: () {
                _searchController.clear();
                ref.read(globalSearchQueryProvider.notifier).state = '';
                setState(() {});
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(
                  Icons.close,
                  size: 13,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],

          // Vertical divider inside search pill
          Container(
            width: 1,
            height: 14,
            color: isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
          ),
          const SizedBox(width: 4),

          // '+' Add Button inside pill
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            iconSize: 17,
            icon: Icon(
              Icons.add,
              size: 17,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            tooltip: widget.currentRoute == '/' ? 'New List' : 'Search & Add Media',
            onPressed: () {
              if (widget.currentRoute == '/') {
                CollectionEditorDialog.show(context);
              } else {
                final activeCol = ref.read(selectedCollectionProvider);
                if (activeCol != null) {
                  MediaSearchDialog.show(context, collectionId: activeCol.id);
                } else {
                  CollectionEditorDialog.show(context);
                }
              }
            },
          ),

          // Layout / Fullscreen / Grid icon
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            icon: Icon(
              Icons.grid_view_rounded,
              size: 15,
              color: isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
            tooltip: 'Home Library',
            onPressed: () {
              if (widget.currentRoute != '/') {
                context.go('/');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRightCluster(
    BuildContext context,
    bool isDark,
    bool isDesktopPlatform,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // '...' More Options Menu (Readest style)
        PopupMenuButton<String>(
          popUpAnimationStyle: AnimationStyle.noAnimation,
          padding: EdgeInsets.zero,
          icon: Icon(
            Icons.more_horiz,
            size: 18,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          tooltip: 'More options',
          onSelected: (val) {
            if (val == 'command_palette') {
              CommandPalette.show(context);
            } else if (val == 'import_export') {
              ImportExportDialog.show(context);
            } else if (val == 'settings') {
              context.go('/settings');
            } else if (val == 'toggle_theme') {
              final current = ref.read(settingsProvider).themeMode;
              ref.read(settingsProvider.notifier).setThemeMode(
                    current == ThemeMode.dark
                        ? ThemeMode.light
                        : ThemeMode.dark,
                  );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'command_palette',
              child: Row(
                children: [
                  Icon(Icons.terminal, size: 16),
                  SizedBox(width: 8),
                  Text('Command Palette (Ctrl+K)'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'import_export',
              child: Row(
                children: [
                  Icon(Icons.import_export, size: 16),
                  SizedBox(width: 8),
                  Text('Import / Export Backup'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined, size: 16),
                  SizedBox(width: 8),
                  Text('Settings & Preferences'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_theme',
              child: Row(
                children: [
                  Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode'),
                ],
              ),
            ),
          ],
        ),

        // Quick Global Search button
        IconButton(
          icon: Icon(
            Icons.menu,
            size: 18,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          tooltip: 'All Collections',
          onPressed: () => context.go('/'),
        ),

        if (isDesktopPlatform) ...[
          const SizedBox(width: 8),
          // Window Controls: Minimize (-)
          _buildWindowButton(
            icon: Icons.remove,
            tooltip: 'Minimize',
            isDark: isDark,
            onPressed: () async {
              try {
                await windowManager.minimize();
              } catch (_) {}
            },
          ),
          // Window Controls: Maximize/Restore (▢)
          _buildWindowButton(
            icon: _isMaximized
                ? Icons.filter_none_rounded
                : Icons.crop_square_rounded,
            tooltip: _isMaximized ? 'Restore' : 'Maximize',
            isDark: isDark,
            onPressed: () async {
              try {
                if (await windowManager.isMaximized()) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              } catch (_) {}
            },
          ),
          // Window Controls: Close (✕)
          _buildWindowButton(
            icon: Icons.close_rounded,
            tooltip: 'Close',
            isDark: isDark,
            isClose: true,
            onPressed: () async {
              try {
                await windowManager.close();
              } catch (_) {}
            },
          ),
        ],
      ],
    );
  }

  Widget _buildWindowButton({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required VoidCallback onPressed,
    bool isClose = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      hoverColor: isClose
          ? AppColors.error
          : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Icon(
          icon,
          size: 14,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}
