import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:void_app/app/app_providers.dart';
import 'package:void_app/core/theme/app_colors.dart';
import 'package:void_app/core/theme/app_typography.dart';
import 'package:void_app/core/utils/id_generator.dart';
import 'package:void_app/features/collections/domain/collection.dart';
import 'package:void_app/features/schemas/data/builtin_schemas.dart';

class CollectionEditorDialog extends ConsumerStatefulWidget {
  final Collection? collection;

  const CollectionEditorDialog({super.key, this.collection});

  static Future<void> show(BuildContext context, {Collection? collection}) {
    return showDialog(
      context: context,
      builder: (context) => CollectionEditorDialog(collection: collection),
    );
  }

  @override
  ConsumerState<CollectionEditorDialog> createState() =>
      _CollectionEditorDialogState();
}

class _CollectionEditorDialogState
    extends ConsumerState<CollectionEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedSchemaId;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.collection?.name ?? '');
    _selectedSchemaId =
        widget.collection?.schemaId ?? BuiltinSchemas.moviesSchemaId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.collection != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Header
                Text(
                  isEditing ? 'Edit List' : 'Create New List',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose a media type for your local collection.',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
                const SizedBox(height: 22),

                // Media Type Cards
                if (!isEditing) ...[
                  Text(
                    'LIST TYPE',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeCard(
                          schemaId: BuiltinSchemas.moviesSchemaId,
                          icon: Icons.movie_outlined,
                          label: 'Movies',
                          sublabel: 'Films & cinema',
                          color: AppColors.movieAccent,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTypeCard(
                          schemaId: BuiltinSchemas.tvShowsSchemaId,
                          icon: Icons.tv,
                          label: 'TV Shows',
                          sublabel: 'Series & anime',
                          color: AppColors.tvAccent,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTypeCard(
                          schemaId: BuiltinSchemas.booksSchemaId,
                          icon: Icons.menu_book,
                          label: 'Books',
                          sublabel: 'Novels & docs',
                          color: AppColors.bookAccent,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // List Name Input
                Text(
                  'LIST NAME',
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    hintText: _getPlaceholderHint(_selectedSchemaId),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'List name is required';
                    }
                    return null;
                  },
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                // Footer Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _isSaving ? null : _handleSave,
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEditing ? 'Save Changes' : 'Create List'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required String schemaId,
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required bool isDark,
  }) {
    final isSelected = _selectedSchemaId == schemaId;

    return Material(
      color: isSelected
          ? (isDark
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.primary.withValues(alpha: 0.08))
          : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            _selectedSchemaId = schemaId;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPlaceholderHint(String schemaId) {
    if (schemaId == BuiltinSchemas.tvShowsSchemaId) {
      return 'e.g. Sci-Fi TV Series, Fall Anime 2026';
    }
    if (schemaId == BuiltinSchemas.booksSchemaId) {
      return 'e.g. 2026 Reading List, Philosophy Books';
    }
    return 'e.g. 2026 Movie Watchlist, Sci-Fi Movies';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(collectionRepositoryProvider);
      final now = DateTime.now();

      String icon = 'movie';
      if (_selectedSchemaId == BuiltinSchemas.tvShowsSchemaId) {
        icon = 'tv';
      } else if (_selectedSchemaId == BuiltinSchemas.booksSchemaId) {
        icon = 'menu_book';
      }

      if (widget.collection != null) {
        final updated = widget.collection!.copyWith(
          name: _nameController.text.trim(),
          updatedAt: now,
        );
        await repo.updateCollection(updated);
      } else {
        final newCol = Collection(
          id: IdGenerator.generate(),
          name: _nameController.text.trim(),
          schemaId: _selectedSchemaId,
          icon: icon,
          createdAt: now,
          updatedAt: now,
        );
        await repo.createCollection(newCol);

        if (mounted) {
          Navigator.of(context).pop();
          context.go('/collection/${newCol.id}');
          return;
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Failed to save list: $e';
      });
    }
  }
}
