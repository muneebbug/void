import 'dart:async';
import 'package:void_app/core/database/app_database.dart';
import 'package:void_app/core/errors/app_exception.dart';
import 'package:void_app/core/validation/validator.dart';
import 'package:void_app/features/collections/domain/collection.dart';

abstract class CollectionRepository {
  Stream<List<Collection>> watchCollections({bool includeDeleted = false});
  Future<List<Collection>> getCollections({bool includeDeleted = false});
  Future<Collection?> getCollectionById(String id);
  Future<void> createCollection(Collection collection);
  Future<void> updateCollection(Collection collection);
  Future<void> deleteCollection(String id);
  Future<void> reorderCollections(List<String> collectionIdsInOrder);
}

class SqliteCollectionRepository implements CollectionRepository {
  final AppDatabase _db;

  SqliteCollectionRepository(this._db);

  @override
  Stream<List<Collection>> watchCollections({
    bool includeDeleted = false,
  }) async* {
    yield await getCollections(includeDeleted: includeDeleted);
    await for (final _ in _db.onCollectionsChanged) {
      yield await getCollections(includeDeleted: includeDeleted);
    }
  }

  @override
  Future<List<Collection>> getCollections({bool includeDeleted = false}) async {
    const sql = 'SELECT * FROM collections ORDER BY position ASC, name ASC';

    final rows = _db.rawDb.select(sql);
    final List<Collection> collections = [];
    for (final row in rows) {
      final id = row['id'] as String;
      final count = _getItemCountForCollection(id);
      collections.add(_mapRowToCollection(row, count));
    }
    return collections;
  }

  @override
  Future<Collection?> getCollectionById(String id) async {
    final rows = _db.rawDb.select(
      'SELECT * FROM collections WHERE id = ?',
      [id],
    );
    if (rows.isEmpty) return null;
    final count = _getItemCountForCollection(id);
    return _mapRowToCollection(rows.first, count);
  }

  int _getItemCountForCollection(String collectionId) {
    final result = _db.rawDb.select(
      'SELECT COUNT(*) as cnt FROM items WHERE collection_id = ? AND parent_item_id IS NULL',
      [collectionId],
    );
    if (result.isEmpty) return 0;
    return (result.first['cnt'] as int? ?? 0);
  }

  @override
  Future<void> createCollection(Collection collection) async {
    final validation = Validator.validateCollection(collection);
    if (validation.isInvalid) {
      throw ValidationException(
        'Collection validation failed',
        details: validation.errors.map((e) => e.message).toList(),
      );
    }

    final now = DateTime.now().toIso8601String();
    _db.rawDb.execute(
      '''
      INSERT INTO collections (id, name, icon, schema_id, position, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    ''',
      [
        collection.id,
        collection.name,
        collection.icon,
        collection.schemaId,
        collection.position,
        collection.createdAt.toIso8601String(),
        now,
      ],
    );

    _db.notifyCollectionsChanged();
  }

  @override
  Future<void> updateCollection(Collection collection) async {
    final validation = Validator.validateCollection(collection);
    if (validation.isInvalid) {
      throw ValidationException(
        'Collection validation failed',
        details: validation.errors.map((e) => e.message).toList(),
      );
    }

    final now = DateTime.now().toIso8601String();
    _db.rawDb.execute(
      '''
      UPDATE collections
      SET name = ?, icon = ?, schema_id = ?, position = ?, updated_at = ?
      WHERE id = ?
    ''',
      [
        collection.name,
        collection.icon,
        collection.schemaId,
        collection.position,
        now,
        collection.id,
      ],
    );

    _db.notifyCollectionsChanged();
  }

  @override
  Future<void> deleteCollection(String id) async {
    _db.transaction(() {
      _db.rawDb.execute('DELETE FROM items WHERE collection_id = ?', [id]);
      _db.rawDb.execute('DELETE FROM collections WHERE id = ?', [id]);
    });

    _db.notifyCollectionsChanged();
    _db.notifyItemsChanged();
  }

  @override
  Future<void> reorderCollections(List<String> collectionIdsInOrder) async {
    final now = DateTime.now().toIso8601String();
    _db.transaction(() {
      for (int i = 0; i < collectionIdsInOrder.length; i++) {
        _db.rawDb.execute(
          'UPDATE collections SET position = ?, updated_at = ? WHERE id = ?',
          [i, now, collectionIdsInOrder[i]],
        );
      }
    });

    _db.notifyCollectionsChanged();
  }

  Collection _mapRowToCollection(Map<String, dynamic> row, int count) {
    return Collection(
      id: row['id'] as String,
      name: row['name'] as String,
      icon: row['icon'] as String?,
      schemaId: row['schema_id'] as String,
      position: row['position'] as int? ?? 0,
      itemCount: count,
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      deletedAt: DateTime.tryParse(row['deleted_at']?.toString() ?? ''),
    );
  }
}
