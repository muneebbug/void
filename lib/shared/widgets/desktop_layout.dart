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
import 'package:void_app/features/items/presentation/providers/item_providers.dart';
import 'package:void_app/features/media_search/presentation/widgets/media_search_dialog.dart';
import 'package:void_app/features/search/presentation/providers/search_provider.dart';
import 'package:void_app/features/settings/presentation/providers/settings_provider.dart';
import 'package:void_app/shared/widgets/elegant_popup_menu.dart';
import 'package:void_app/shared/widgets/view_options_menu.dart';
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
  final GlobalKey _viewOptionsKey = GlobalKey();
  final GlobalKey _appMenuKey = GlobalKey();
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
    final isDesktopPlatform =
        !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background drag area (draggable across the entire titlebar empty spaces)
          if (isDesktopPlatform)
            const Positioned.fill(
              child: DragToMoveArea(
                child: SizedBox.expand(),
              ),
            ),

          // Foreground interactive elements (search pill, cluster, window controls)
          Row(
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
        ],
      ),
    );
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
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
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
              mouseCursor: SystemMouseCursors.click,
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
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
            tooltip:
                widget.currentRoute.startsWith('/collection/')
                    ? 'Add Item to List'
                    : 'New List',
            onPressed: () {
              if (widget.currentRoute.startsWith('/collection/')) {
                final segments = widget.currentRoute.split('/');
                final colId = segments.length > 2 ? segments[2] : null;
                if (colId != null) {
                  MediaSearchDialog.show(context, collectionId: colId);
                  return;
                }
              }
              CollectionEditorDialog.show(context);
            },
          ),

          // Layout / Fullscreen / Grid icon
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            icon: Icon(
              Icons.grid_view_rounded,
              size: 15,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
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
        // '...' Page & View Options Menu (Readest style)
        IconButton(
          key: _viewOptionsKey,
          icon: Icon(
            Icons.more_horiz,
            size: 18,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          tooltip: 'View options',
          onPressed: () {
            final isAllListsPage =
                widget.currentRoute == '/' || widget.currentRoute == '/home';

            String? activeCollectionId;
            if (widget.currentRoute.startsWith('/collection/')) {
              activeCollectionId = widget.currentRoute
                  .substring('/collection/'.length)
                  .split('?')
                  .first;
            }

            final collections = ref.read(collectionsStreamProvider).value ?? [];
            final currentCollection = activeCollectionId != null
                ? collections
                    .where((c) => c.id == activeCollectionId)
                    .firstOrNull
                : null;

            ViewOptionsMenu.show(
              context: context,
              anchorKey: _viewOptionsKey,
              currentCollection: currentCollection,
              isAllListsPage: isAllListsPage,
            );
          },
        ),

        // '≡' App Menu (Settings, Theme, Navigation)
        IconButton(
          key: _appMenuKey,
          icon: Icon(
            Icons.menu,
            size: 18,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          tooltip: 'App menu',
          onPressed: () async {
            final currentTheme = ref.read(settingsProvider).themeMode;
            final isDarkMode = currentTheme == ThemeMode.dark;

            final selected = await ElegantPopupMenu.show<String>(
              context: context,
              anchorKey: _appMenuKey,
              items: [
                const ElegantMenuItem(
                  value: 'settings',
                  label: 'Settings',
                  icon: Icons.settings_outlined,
                ),
                ElegantMenuItem(
                  value: 'toggle_theme',
                  label: isDarkMode ? 'Light Mode' : 'Dark Mode',
                  icon: isDarkMode
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
                const ElegantMenuItem(
                  value: 'all_lists',
                  label: 'All Lists',
                  icon: Icons.grid_view_rounded,
                ),
              ],
            );

            if (selected == 'settings') {
              if (context.mounted) context.go('/settings');
            } else if (selected == 'toggle_theme') {
              await ref.read(settingsProvider.notifier).setThemeMode(
                    isDarkMode ? ThemeMode.light : ThemeMode.dark,
                  );
            } else if (selected == 'all_lists') {
              if (context.mounted) context.go('/');
            }
          },
        ),

        if (isDesktopPlatform) ...[
          const SizedBox(width: 8),
          // Window Controls: Minimize (-)
          _buildWindowButton(
            icon: Icons.remove,
            tooltip: 'Minimize',
            isDark: isDark,
            onPressed: () {
              try {
                windowManager.minimize();
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
            onPressed: () {
              try {
                if (_isMaximized) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
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
            onPressed: () {
              try {
                windowManager.close();
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
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          hoverColor: isClose
              ? AppColors.error
              : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            child: Icon(
              icon,
              size: 14,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ),
    );
  }
}
