import 'dart:async';
import 'package:void_app/core/database/app_database.dart';
import 'package:void_app/core/errors/app_exception.dart';
import 'package:void_app/core/serialization/field_value_serializer.dart';
import 'package:void_app/core/validation/validator.dart';
import 'package:void_app/features/items/domain/item.dart';
import 'package:void_app/features/schemas/data/schema_repository.dart';

abstract class ItemRepository {
  Stream<List<Item>> watchItems({
    String? collectionId,
    String? schemaId,
    String? parentItemId,
    bool includeDeleted = false,
  });

  Future<List<Item>> getItems({
    String? collectionId,
    String? schemaId,
    String? parentItemId,
    bool includeDeleted = false,
  });

  Future<Item?> getItemById(String id, {bool includeSubItems = true});
  Future<void> createItem(Item item);
  Future<void> updateItem(Item item);
  Future<void> deleteItem(String id);
  Future<void> permanentlyDeleteItem(String id);
  Future<void> reorderItems(List<String> itemIdsInOrder);
}

class SqliteItemRepository implements ItemRepository {
  final AppDatabase _db;
  final SchemaRepository _schemaRepository;

  SqliteItemRepository(this._db, this._schemaRepository);

  @override
  Stream<List<Item>> watchItems({
    String? collectionId,
    String? schemaId,
    String? parentItemId,
    bool includeDeleted = false,
  }) async* {
    yield await getItems(
      collectionId: collectionId,
      schemaId: schemaId,
      parentItemId: parentItemId,
      includeDeleted: includeDeleted,
    );

    await for (final _ in _db.onItemsChanged) {
      yield await getItems(
        collectionId: collectionId,
        schemaId: schemaId,
        parentItemId: parentItemId,
        includeDeleted: includeDeleted,
      );
    }
  }

  @override
  Future<List<Item>> getItems({
    String? collectionId,
    String? schemaId,
    String? parentItemId,
    bool includeDeleted = false,
  }) async {
    final List<String> conditions = [];
    final List<dynamic> params = [];

    if (collectionId != null) {
      conditions.add('collection_id = ?');
      params.add(collectionId);
    }

    if (schemaId != null) {
      conditions.add('schema_id = ?');
      params.add(schemaId);
    }

    if (parentItemId != null) {
      conditions.add('parent_item_id = ?');
      params.add(parentItemId);
    } else {
      conditions.add('parent_item_id IS NULL');
    }

    final whereClause =
        conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final sql =
        'SELECT * FROM items $whereClause ORDER BY position ASC, created_at DESC';

    final rows = _db.rawDb.select(sql, params);
    final List<Item> items = [];
    for (final row in rows) {
      final sId = row['schema_id'] as String;
      final schema = await _schemaRepository.getSchemaById(sId);
      final fields = schema?.fields ?? [];
      final id = row['id'] as String;
      final subItems = await _getSubItems(id);
      items.add(_mapRowToItem(row, fields, subItems));
    }
    return items;
  }

  @override
  Future<Item?> getItemById(String id, {bool includeSubItems = true}) async {
    final rows = _db.rawDb.select(
      'SELECT * FROM items WHERE id = ?',
      [id],
    );
    if (rows.isEmpty) return null;

    final row = rows.first;
    final sId = row['schema_id'] as String;
    final schema = await _schemaRepository.getSchemaById(sId);
    final fields = schema?.fields ?? [];
    final subItems = includeSubItems ? await _getSubItems(id) : <Item>[];
    return _mapRowToItem(row, fields, subItems);
  }

  Future<List<Item>> _getSubItems(String parentItemId) async {
    final rows = _db.rawDb.select(
      'SELECT * FROM items WHERE parent_item_id = ? ORDER BY position ASC, created_at ASC',
      [parentItemId],
    );

    final List<Item> subItems = [];
    for (final row in rows) {
      final sId = row['schema_id'] as String;
      final schema = await _schemaRepository.getSchemaById(sId);
      final fields = schema?.fields ?? [];
      subItems.add(_mapRowToItem(row, fields, const []));
    }
    return subItems;
  }

  @override
  Future<void> createItem(Item item) async {
    final schema = await _schemaRepository.getSchemaById(item.schemaId);
    if (schema == null) {
      throw NotFoundException('Schema ${item.schemaId} not found');
    }

    final validation = Validator.validateItem(item, schema);
    if (validation.isInvalid) {
      throw ValidationException(
        'Item validation failed',
        details: validation.errors.map((e) => e.message).toList(),
      );
    }

    final now = DateTime.now().toIso8601String();
    final dataJson = FieldValueSerializer.toJsonString(item.data);

    _db.rawDb.execute(
      '''
      INSERT INTO items (
        id, collection_id, schema_id, parent_item_id, title,
        cover_image, data, external_source, external_id, position,
        created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
      [
        item.id,
        item.collectionId,
        item.schemaId,
        item.parentItemId,
        item.title,
        item.coverImage,
        dataJson,
        item.externalSource,
        item.externalId,
        item.position,
        item.createdAt.toIso8601String(),
        now,
      ],
    );

    _db.notifyItemsChanged();
    _db.notifyCollectionsChanged();
  }

  @override
  Future<void> updateItem(Item item) async {
    final schema = await _schemaRepository.getSchemaById(item.schemaId);
    if (schema == null) {
      throw NotFoundException('Schema ${item.schemaId} not found');
    }

    final validation = Validator.validateItem(item, schema);
    if (validation.isInvalid) {
      throw ValidationException(
        'Item validation failed',
        details: validation.errors.map((e) => e.message).toList(),
      );
    }

    final now = DateTime.now().toIso8601String();
    final dataJson = FieldValueSerializer.toJsonString(item.data);

    _db.rawDb.execute(
      '''
      UPDATE items SET
        collection_id = ?,
        title = ?,
        cover_image = ?,
        data = ?,
        external_source = ?,
        external_id = ?,
        position = ?,
        updated_at = ?
      WHERE id = ?
    ''',
      [
        item.collectionId,
        item.title,
        item.coverImage,
        dataJson,
        item.externalSource,
        item.externalId,
        item.position,
        now,
        item.id,
      ],
    );

    _db.notifyItemsChanged();
    _db.notifyCollectionsChanged();
  }

  @override
  Future<void> deleteItem(String id) async {
    await permanentlyDeleteItem(id);
  }

  @override
  Future<void> permanentlyDeleteItem(String id) async {
    _db.transaction(() {
      _db.rawDb.execute('DELETE FROM items WHERE parent_item_id = ?', [id]);
      _db.rawDb.execute('DELETE FROM items WHERE id = ?', [id]);
    });

    _db.notifyItemsChanged();
    _db.notifyCollectionsChanged();
  }

  @override
  Future<void> reorderItems(List<String> itemIdsInOrder) async {
    final now = DateTime.now().toIso8601String();
    _db.transaction(() {
      for (int i = 0; i < itemIdsInOrder.length; i++) {
        _db.rawDb.execute(
          'UPDATE items SET position = ?, updated_at = ? WHERE id = ?',
          [i, now, itemIdsInOrder[i]],
        );
      }
    });

    _db.notifyItemsChanged();
  }

  Item _mapRowToItem(
    Map<String, dynamic> row,
    List<dynamic> fields,
    List<Item> subItems,
  ) {
    final dataStr = row['data'] as String? ?? '{}';
    final data = FieldValueSerializer.fromJsonString(
      dataStr,
      schemaFields: fields.cast(),
    );

    return Item(
      id: row['id'] as String,
      collectionId: row['collection_id'] as String?,
      schemaId: row['schema_id'] as String,
      parentItemId: row['parent_item_id'] as String?,
      title: row['title'] as String,
      coverImage: row['cover_image'] as String?,
      data: data,
      externalSource: row['external_source'] as String?,
      externalId: row['external_id'] as String?,
      position: row['position'] as int? ?? 0,
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      deletedAt: DateTime.tryParse(row['deleted_at']?.toString() ?? ''),
      subItems: subItems,
    );
  }
}
