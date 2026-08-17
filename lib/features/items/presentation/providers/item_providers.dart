import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_app/app/app_providers.dart';
import 'package:void_app/core/utils/id_generator.dart';
import 'package:void_app/core/validation/validation_result.dart';
import 'package:void_app/core/validation/validator.dart';
import 'package:void_app/features/items/domain/field_value.dart';
import 'package:void_app/features/items/domain/item.dart';
import 'package:void_app/features/schemas/presentation/providers/schema_providers.dart';

class SelectedItemIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  @override
  set state(String? value) => super.state = value;
  void select(String? id) => state = id;
}

final selectedItemIdProvider =
    NotifierProvider<SelectedItemIdNotifier, String?>(
  SelectedItemIdNotifier.new,
);

final collectionItemsProvider =
    StreamProvider.family<List<Item>, String>((ref, collectionId) {
  final repo = ref.watch(itemRepositoryProvider);
  return repo.watchItems(collectionId: collectionId);
});

final collectionItemsStreamProvider = collectionItemsProvider;

final allItemsStreamProvider = StreamProvider<List<Item>>((ref) {
  final repo = ref.watch(itemRepositoryProvider);
  return repo.watchItems();
});

final itemDetailProvider = FutureProvider.family<Item?, String>((ref, itemId) {
  final repo = ref.watch(itemRepositoryProvider);
  return repo.getItemById(itemId);
});

final itemDetailStreamProvider =
    StreamProvider.family<Item?, String>((ref, itemId) async* {
  final repo = ref.watch(itemRepositoryProvider);
  final item = await repo.getItemById(itemId);
  yield item;
});

class ItemActionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<Item> createManualItem({
    required String title,
    required String collectionId,
    required String schemaId,
    String? coverImage,
    Map<String, FieldValue> data = const {},
  }) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final item = Item(
        id: IdGenerator.generate(),
        collectionId: collectionId,
        schemaId: schemaId,
        title: title,
        coverImage: coverImage,
        data: data,
        createdAt: now,
        updatedAt: now,
      );

      final repo = ref.read(itemRepositoryProvider);
      await repo.createItem(item);
      state = const AsyncValue.data(null);
      return item;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateItem(Item item) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(itemRepositoryProvider);
      await repo.updateItem(item);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteItem(String id) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(itemRepositoryProvider);
      await repo.deleteItem(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> permanentlyDeleteItem(String id) async {
    return deleteItem(id);
  }
}

final itemActionProvider =
    NotifierProvider<ItemActionNotifier, AsyncValue<void>>(
  ItemActionNotifier.new,
);

class ItemEditorState {
  final Item item;
  final bool isSaving;
  final bool hasUnsavedChanges;
  final ValidationResult validationResult;

  const ItemEditorState({
    required this.item,
    this.isSaving = false,
    this.hasUnsavedChanges = false,
    this.validationResult = ValidationResult.valid,
  });

  ItemEditorState copyWith({
    Item? item,
    bool? isSaving,
    bool? hasUnsavedChanges,
    ValidationResult? validationResult,
  }) {
    return ItemEditorState(
      item: item ?? this.item,
      isSaving: isSaving ?? this.isSaving,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      validationResult: validationResult ?? this.validationResult,
    );
  }
}

class ItemEditorNotifier extends Notifier<ItemEditorState> {
  final Item initialItem;

  ItemEditorNotifier(this.initialItem);

  @override
  ItemEditorState build() {
    return ItemEditorState(item: initialItem);
  }

  void updateTitle(String title) {
    state = state.copyWith(
      item: state.item.copyWith(title: title),
      hasUnsavedChanges: true,
    );
  }

  void updateCoverImage(String? url) {
    state = state.copyWith(
      item: state.item.copyWith(coverImage: url),
      hasUnsavedChanges: true,
    );
  }

  void updateField(String key, FieldValue value) {
    final newData = Map<String, FieldValue>.from(state.item.data);
    newData[key] = value;
    state = state.copyWith(
      item: state.item.copyWith(data: newData),
      hasUnsavedChanges: true,
    );
  }

  void addSubItem(String title) {
    final sub = Item(
      id: IdGenerator.generate(),
      collectionId: state.item.collectionId,
      schemaId: state.item.schemaId,
      parentItemId: state.item.id,
      title: title,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final updatedSubs = List<Item>.from(state.item.subItems)..add(sub);
    state = state.copyWith(
      item: state.item.copyWith(subItems: updatedSubs),
      hasUnsavedChanges: true,
    );
  }

  void removeSubItem(String subId) {
    final updatedSubs =
        state.item.subItems.where((s) => s.id != subId).toList();
    state = state.copyWith(
      item: state.item.copyWith(subItems: updatedSubs),
      hasUnsavedChanges: true,
    );
  }

  Future<bool> save() async {
    final schema =
        await ref.read(schemaDetailProvider(state.item.schemaId).future);
    if (schema == null) return false;

    final validation = Validator.validateItem(state.item, schema);
    if (validation.isInvalid) {
      state = state.copyWith(validationResult: validation);
      return false;
    }

    state = state.copyWith(
      isSaving: true,
      validationResult: ValidationResult.valid,
    );
    try {
      final repo = ref.read(itemRepositoryProvider);
      await repo.updateItem(state.item);
      state = state.copyWith(isSaving: false, hasUnsavedChanges: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false);
      return false;
    }
  }
}

final itemEditorProvider =
    NotifierProvider.autoDispose.family<ItemEditorNotifier, ItemEditorState, Item>(
  ItemEditorNotifier.new,
);
