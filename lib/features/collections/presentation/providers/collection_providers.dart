import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_app/app/app_providers.dart';
import 'package:void_app/core/utils/id_generator.dart';
import 'package:void_app/features/collections/domain/collection.dart';

final collectionsStreamProvider = StreamProvider<List<Collection>>((ref) {
  final repo = ref.watch(collectionRepositoryProvider);
  return repo.watchCollections();
});

class SelectedCollectionIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  @override
  set state(String? value) => super.state = value;
  void select(String? id) => state = id;
}

final selectedCollectionIdProvider =
    NotifierProvider<SelectedCollectionIdNotifier, String?>(
  SelectedCollectionIdNotifier.new,
);

final selectedCollectionProvider = Provider<Collection?>((ref) {
  final id = ref.watch(selectedCollectionIdProvider);
  if (id == null) return null;
  final collections = ref.watch(collectionsStreamProvider).value ?? [];
  return collections.where((c) => c.id == id).firstOrNull;
});

final collectionDetailProvider =
    FutureProvider.family<Collection?, String>((ref, id) {
  final repo = ref.watch(collectionRepositoryProvider);
  return repo.getCollectionById(id);
});

class CollectionActionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<Collection> createCollection({
    required String name,
    required String schemaId,
    String? icon,
  }) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final collection = Collection(
        id: IdGenerator.generate(),
        name: name,
        schemaId: schemaId,
        icon: icon,
        createdAt: now,
        updatedAt: now,
      );

      final repo = ref.read(collectionRepositoryProvider);
      await repo.createCollection(collection);
      state = const AsyncValue.data(null);
      return collection;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateCollection(Collection collection) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(collectionRepositoryProvider);
      await repo.updateCollection(collection);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteCollection(String id) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(collectionRepositoryProvider);
      await repo.deleteCollection(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final collectionActionProvider =
    NotifierProvider<CollectionActionNotifier, AsyncValue<void>>(
  CollectionActionNotifier.new,
);
