import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_app/app/app_providers.dart';
import 'package:void_app/core/theme/app_colors.dart';
import 'package:void_app/core/theme/app_typography.dart';
import 'package:void_app/features/collections/presentation/providers/collection_providers.dart';

class ImportExportDialog extends ConsumerStatefulWidget {
  final String? initialCollectionId;

  const ImportExportDialog({super.key, this.initialCollectionId});

  static Future<void> show(
    BuildContext context, {
    String? initialCollectionId,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ImportExportDialog(
        initialCollectionId: initialCollectionId,
      ),
    );
  }

  @override
  ConsumerState<ImportExportDialog> createState() => _ImportExportDialogState();
}

class _ImportExportDialogState extends ConsumerState<ImportExportDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _importTextController = TextEditingController();
  String? _selectedCollectionId;
  String _exportFormat = 'json'; // json or csv
  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedCollectionId = widget.initialCollectionId;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importTextController.dispose();
    super.dispose();
  }

  Future<void> _handleExport() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final service = ref.read(importExportServiceProvider);
      String content;

      if (_exportFormat == 'csv') {
        if (_selectedCollectionId == null) {
          throw Exception('Please select a collection to export CSV');
        }
        content = await service.exportToCsv(
          collectionId: _selectedCollectionId!,
        );
      } else {
        content = await service.exportToJson(
          collectionId: _selectedCollectionId,
        );
      }

      await Clipboard.setData(ClipboardData(text: content));
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _statusMessage =
            'Exported successfully! Content (${content.length} characters) copied to Clipboard.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _statusMessage = 'Export failed: $e';
      });
    }
  }

  Future<void> _handleImport() async {
    final text = _importTextController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _isSuccess = false;
        _statusMessage = 'Please paste JSON or CSV content to import';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final service = ref.read(importExportServiceProvider);
      int importedCount = 0;

      if (text.startsWith('{') || text.startsWith('[')) {
        // JSON Import
        importedCount = await service.importFromJson(text);
      } else {
        // CSV Import
        if (_selectedCollectionId == null) {
          throw Exception('Please select a target collection for CSV import');
        }
        importedCount = await service.importFromCsv(
          csvContent: text,
          collectionId: _selectedCollectionId!,
        );
      }

      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _statusMessage = 'Successfully imported $importedCount records!';
        _importTextController.clear();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _statusMessage = 'Import failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final collectionsAsync = ref.watch(collectionsStreamProvider);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.import_export,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Import / Export Data',
                      style: AppTypography.titleMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Export Backup'),
                Tab(text: 'Import Data'),
              ],
            ),
            const Divider(height: 1),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 1. Export Tab
                  _buildExportTab(collectionsAsync, isDark),

                  // 2. Import Tab
                  _buildImportTab(collectionsAsync, isDark),
                ],
              ),
            ),

            if (_statusMessage != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                color: _isSuccess
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.error.withValues(alpha: 0.15),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle : Icons.error_outline,
                      size: 16,
                      color: _isSuccess ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: AppTypography.bodySmall.copyWith(
                          color:
                              _isSuccess ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Footer
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportTab(
    AsyncValue<List<dynamic>> collectionsAsync,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Export format',
          style: AppTypography.labelSmall.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'json',
              label: Text('JSON (Full Database / Schemas)'),
              icon: Icon(Icons.code, size: 16),
            ),
            ButtonSegment(
              value: 'csv',
              label: Text('CSV (Single Collection)'),
              icon: Icon(Icons.table_chart, size: 16),
            ),
          ],
          selected: {_exportFormat},
          onSelectionChanged: (val) {
            setState(() => _exportFormat = val.first);
          },
        ),
        const SizedBox(height: 20),

        // Collection Filter Selector
        collectionsAsync.when(
          data: (cols) {
            return DropdownButtonFormField<String?>(
              initialValue: _selectedCollectionId,
              decoration: InputDecoration(
                labelText: _exportFormat == 'csv'
                    ? 'Target Collection *'
                    : 'Filter by Collection (Optional)',
              ),
              items: [
                if (_exportFormat != 'csv')
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Collections & Schemas'),
                  ),
                ...cols.map(
                  (c) => DropdownMenuItem(
                    value: c.id as String,
                    child: Text(c.name as String),
                  ),
                ),
              ],
              onChanged: (val) => setState(() => _selectedCollectionId = val),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
        ),
        const SizedBox(height: 24),

        ElevatedButton.icon(
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.copy, size: 18),
          label: const Text('Export & Copy to Clipboard'),
          onPressed: _isLoading ? null : _handleExport,
        ),
      ],
    );
  }

  Widget _buildImportTab(
    AsyncValue<List<dynamic>> collectionsAsync,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Target Collection (for CSV import)',
          style: AppTypography.labelSmall.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        collectionsAsync.when(
          data: (cols) {
            return DropdownButtonFormField<String?>(
              initialValue: _selectedCollectionId,
              decoration: const InputDecoration(
                labelText: 'Select Collection (Required for CSV)',
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('None (Auto-create from JSON backup)'),
                ),
                ...cols.map(
                  (c) => DropdownMenuItem(
                    value: c.id as String,
                    child: Text(c.name as String),
                  ),
                ),
              ],
              onChanged: (val) => setState(() => _selectedCollectionId = val),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _importTextController,
          maxLines: 8,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          decoration: const InputDecoration(
            labelText: 'Paste JSON Backup or CSV Content',
            hintText:
                '{\n  "schemas": [...],\n  "collections": [...],\n  "items": [...]\n}',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.file_download, size: 18),
          label: const Text('Validate & Import Records'),
          onPressed: _isLoading ? null : _handleImport,
        ),
      ],
    );
  }
}
