import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_app/app/app_providers.dart';
import 'package:void_app/core/theme/app_colors.dart';
import 'package:void_app/core/theme/app_typography.dart';
import 'package:void_app/core/utils/id_generator.dart';
import 'package:void_app/core/validation/validator.dart';
import 'package:void_app/features/collections/presentation/providers/collection_providers.dart';
import 'package:void_app/features/items/domain/field_value.dart';
import 'package:void_app/features/items/domain/item.dart';
import 'package:void_app/features/items/presentation/widgets/field_input_widgets.dart';
import 'package:void_app/features/schemas/domain/schema.dart';
import 'package:void_app/features/schemas/presentation/providers/schema_providers.dart';
import 'package:void_app/shared/widgets/void_image.dart';

class ItemEditorDialog extends ConsumerStatefulWidget {
  final Item? item;
  final String? collectionId;
  final String? schemaId;
  final String? parentItemId;

  const ItemEditorDialog({
    super.key,
    this.item,
    this.collectionId,
    this.schemaId,
    this.parentItemId,
  });

  static Future<void> show(
    BuildContext context, {
    Item? item,
    String? collectionId,
    String? schemaId,
    String? parentItemId,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ItemEditorDialog(
        item: item,
        collectionId: collectionId,
        schemaId: schemaId,
        parentItemId: parentItemId,
      ),
    );
  }

  @override
  ConsumerState<ItemEditorDialog> createState() => _ItemEditorDialogState();
}

class _ItemEditorDialogState extends ConsumerState<ItemEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _coverImageController;
  final Map<String, FieldValue> _fieldValues = {};
  final List<Item> _subItems = [];
  final TextEditingController _subItemInputController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;
  Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _coverImageController =
        TextEditingController(text: widget.item?.coverImage ?? '');

    if (widget.item != null) {
      _fieldValues.addAll(widget.item!.data);
      _subItems.addAll(widget.item!.subItems);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _coverImageController.dispose();
    _subItemInputController.dispose();
    super.dispose();
  }

  void _handleAddSubItem() {
    final title = _subItemInputController.text.trim();
    if (title.isEmpty) return;

    final subItem = Item(
      id: IdGenerator.generate(),
      collectionId: widget.collectionId ?? widget.item?.collectionId,
      schemaId: widget.schemaId ?? widget.item?.schemaId ?? '',
      parentItemId: widget.item?.id,
      title: title,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _subItems.add(subItem);
      _subItemInputController.clear();
    });
  }

  void _handleRemoveSubItem(int index) {
    setState(() {
      _subItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolve schema: either from item, schemaId parameter, or collectionId parameter
    String effectiveSchemaId = widget.item?.schemaId ?? widget.schemaId ?? '';
    if (effectiveSchemaId.isEmpty && widget.collectionId != null) {
      final colAsync =
          ref.watch(collectionDetailProvider(widget.collectionId!));
      effectiveSchemaId = colAsync.value?.schemaId ?? '';
    }

    final AsyncValue<Schema?> schemaAsync = effectiveSchemaId.isNotEmpty
        ? ref.watch(schemaDetailProvider(effectiveSchemaId))
        : const AsyncValue<Schema?>.loading();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
            _handleSave(schemaAsync.value),
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () =>
            _handleSave(schemaAsync.value),
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
          child: Column(
            children: [
              // Dialog Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_note : Icons.add_box_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Item' : 'New Item',
                            style: AppTypography.titleMedium.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          schemaAsync.when(
                            data: (s) => Text(
                              s != null ? 'Schema: ${s.name}' : '',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Dynamic Form Body
              Expanded(
                child: schemaAsync.when(
                  data: (schema) {
                    if (schema == null) {
                      return const Center(child: Text('Schema not found'));
                    }
                    return _buildForm(schema, isDark);
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (e, _) => Center(
                    child: Text('Error loading schema: $e'),
                  ),
                ),
              ),

              // Dialog Footer
              const Divider(height: 1),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Row(
                  children: [
                    if (_errorMessage != null)
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      Text(
                        'Ctrl+S to save',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () => _handleSave(schemaAsync.value),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEditing ? 'Save Changes' : 'Create Item'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(Schema schema, bool isDark) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Title Field (Primary entity title)
          TextFormField(
            controller: _titleController,
            autofocus: true,
            style: AppTypography.titleMedium.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              labelText: 'Title *',
              hintText: 'Enter title...',
              errorText: _fieldErrors['title'],
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Title is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Cover Image URL Field
          TextFormField(
            controller: _coverImageController,
            decoration: const InputDecoration(
              labelText: 'Cover Image URL (Optional)',
              hintText: 'https://example.com/cover.jpg',
              suffixIcon: Icon(Icons.image_outlined, size: 18),
            ),
            onChanged: (val) => setState(() {}),
          ),
          if (_coverImageController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: VoidImage(
                imageUrl: _coverImageController.text.trim(),
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: Container(
                  height: 140,
                  color: Colors.grey.withValues(alpha: 0.1),
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined, size: 36),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Dynamic Schema Fields
          if (schema.fields.isNotEmpty) ...[
            Text(
              'SCHEMA FIELDS',
              style: AppTypography.labelSmall.copyWith(
                fontSize: 11,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            for (final field in schema.fields) ...[
              DynamicFieldInput(
                field: field,
                value: _fieldValues[field.key],
                errorText: _fieldErrors[field.key],
                onChanged: (newVal) {
                  setState(() {
                    _fieldValues[field.key] = newVal;
                    _fieldErrors.remove(field.key);
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
          ],

          const SizedBox(height: 12),
          // Sub-items / Checklist Section
          Text(
            'SUB-ITEMS / CHECKLIST',
            style: AppTypography.labelSmall.copyWith(
              fontSize: 11,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _subItemInputController,
                  decoration: const InputDecoration(
                    hintText: 'Add sub-item or chapter/task...',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: (_) => _handleAddSubItem(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.add, size: 18),
                onPressed: _handleAddSubItem,
              ),
            ],
          ),
          if (_subItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _subItems.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final sub = _subItems[idx];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.subdirectory_arrow_right,
                      size: 16,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                    title: Text(sub.title, style: AppTypography.bodyMedium),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => _handleRemoveSubItem(idx),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleSave(Schema? schema) async {
    if (schema == null) return;
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final coverImage = _coverImageController.text.trim().isNotEmpty
        ? _coverImageController.text.trim()
        : null;

    final candidateItem = Item(
      id: widget.item?.id ?? IdGenerator.generate(),
      collectionId: widget.collectionId ?? widget.item?.collectionId,
      schemaId: schema.id,
      parentItemId: widget.parentItemId ?? widget.item?.parentItemId,
      title: title,
      coverImage: coverImage,
      data: _fieldValues,
      position: widget.item?.position ?? 0,
      createdAt: widget.item?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      subItems: _subItems,
    );

    // Validate domain constraints
    final validation = Validator.validateItem(candidateItem, schema);
    if (validation.isInvalid) {
      final Map<String, String> errors = {};
      for (final err in validation.errors) {
        errors[err.fieldKey] = err.message;
      }
      setState(() {
        _fieldErrors = errors;
        _errorMessage = 'Please fix validation errors';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final itemRepo = ref.read(itemRepositoryProvider);
      if (widget.item != null) {
        await itemRepo.updateItem(candidateItem);
      } else {
        await itemRepo.createItem(candidateItem);
      }

      // Save sub-items if new
      for (final sub in _subItems) {
        final existing = await itemRepo.getItemById(sub.id);
        if (existing == null) {
          final completeSub = sub.copyWith(parentItemId: candidateItem.id);
          await itemRepo.createItem(completeSub);
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Failed to save item: $e';
      });
    }
  }
}
