import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_app/core/theme/app_colors.dart';
import 'package:void_app/core/theme/app_typography.dart';
import 'package:void_app/features/collections/presentation/providers/collection_providers.dart';
import 'package:void_app/features/import_export/presentation/widgets/import_export_dialog.dart';
import 'package:void_app/features/items/presentation/providers/item_providers.dart';
import 'package:void_app/features/schemas/presentation/providers/schema_providers.dart';
import 'package:void_app/features/settings/presentation/providers/settings_provider.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final settings = ref.watch(settingsProvider);
    final collectionsAsync = ref.watch(collectionsStreamProvider);
    final schemasAsync = ref.watch(schemasStreamProvider);
    final itemsAsync = ref.watch(allItemsStreamProvider);

    final collectionsCount = collectionsAsync.value?.length ?? 0;
    final schemasCount = schemasAsync.value?.length ?? 0;
    final totalItemsCount = itemsAsync.value?.length ?? 0;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        children: [
          Text(
            'Settings & Preferences',
            style: AppTypography.titleLarge.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Configure VOID desktop application parameters and database storage.',
            style: AppTypography.bodySmall.copyWith(
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 24),

          // Appearance Section
          _buildSectionHeader('APPEARANCE & THEME', isDark),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Theme Mode',
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Choose dark, light, or follow system default',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode, size: 16),
                            label: Text('Dark'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode, size: 16),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.settings_suggest, size: 16),
                            label: Text('System'),
                          ),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (val) {
                          ref
                              .read(settingsProvider.notifier)
                              .setThemeMode(val.first);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          // Database & Storage Section
          _buildSectionHeader('LOCAL DATABASE & STORAGE', isDark),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.storage_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'SQLite Local Database',
                        style: AppTypography.titleSmall.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    'Active Collections',
                    '$collectionsCount',
                    isDark,
                  ),
                  _buildStatRow(
                    'Total Items',
                    '$totalItemsCount',
                    isDark,
                  ),
                  _buildStatRow(
                    'Defined Schemas',
                    '$schemasCount',
                    isDark,
                  ),
                  _buildStatRow(
                    'Architecture',
                    'Local-First Reactive SQLite',
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.import_export, size: 18),
                        label: const Text('Export / Import Data Backup'),
                        onPressed: () => ImportExportDialog.show(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          // Shortcuts & Keyboard Ergonomics
          _buildSectionHeader('KEYBOARD SHORTCUTS', isDark),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildShortcutRow(
                    'Ctrl/Cmd + K',
                    'Quick Switcher & Command Palette',
                    isDark,
                  ),
                  const Divider(height: 12),
                  _buildShortcutRow(
                    'Ctrl/Cmd + N',
                    'Create new record in active collection',
                    isDark,
                  ),
                  const Divider(height: 12),
                  _buildShortcutRow(
                    'Ctrl/Cmd + S',
                    'Save form in record editor dialog',
                    isDark,
                  ),
                  const Divider(height: 12),
                  _buildShortcutRow(
                    'Ctrl/Cmd + F',
                    'Focus Search view',
                    isDark,
                  ),
                  const Divider(height: 12),
                  _buildShortcutRow(
                    'Esc',
                    'Close active dialog or inspector',
                    isDark,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          // About VOID
          _buildSectionHeader('ABOUT', isDark),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'V',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VOID v1.0.0',
                        style: AppTypography.titleSmall.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        'Production-quality local-first desktop application for organized knowledge & media.',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutRow(String shortcut, String description, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(description, style: AppTypography.bodyMedium),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Text(
            shortcut,
            style: AppTypography.labelSmall.copyWith(
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
