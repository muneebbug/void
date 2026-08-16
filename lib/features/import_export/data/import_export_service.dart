import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:void_app/core/database/app_database.dart';
import 'package:void_app/core/errors/app_exception.dart';
import 'package:void_app/core/serialization/field_value_serializer.dart';
import 'package:void_app/core/utils/id_generator.dart';
import 'package:void_app/features/collections/data/collection_repository.dart';
import 'package:void_app/features/collections/domain/collection.dart';
import 'package:void_app/features/items/data/item_repository.dart';
import 'package:void_app/features/items/domain/field_value.dart';
import 'package:void_app/features/items/domain/item.dart';
import 'package:void_app/features/schemas/data/schema_repository.dart';
import 'package:void_app/features/schemas/domain/field_type.dart';
import 'package:void_app/features/schemas/domain/schema.dart';

class ImportExportService {
  final AppDatabase _db;
  final SchemaRepository _schemaRepo;
  final CollectionRepository _collectionRepo;
  final ItemRepository _itemRepo;

  ImportExportService(
    this._db,
    this._schemaRepo,
    this._collectionRepo,
    this._itemRepo,
  );

  /// Exports entire database or filtered collection to JSON
  Future<String> exportToJson({String? collectionId}) async {
    final schemas = await _schemaRepo.getSchemas();
    final collections = await _collectionRepo.getCollections();
    final items = await _itemRepo.getItems(
      collectionId: collectionId,
      includeDeleted: false,
    );

    final exportMap = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'schemas': schemas.map((s) => s.toJson()).toList(),
      'collections': (collectionId != null
              ? collections.where((c) => c.id == collectionId)
              : collections)
          .map((c) => c.toJson())
          .toList(),
      'items': items
          .map(
            (item) => {
              'id': item.id,
              'collection_id': item.collectionId,
              'schema_id': item.schemaId,
              'parent_item_id': item.parentItemId,
              'title': item.title,
              'cover_image': item.coverImage,
              'data': FieldValueSerializer.toRawMap(item.data),
              'external_source': item.externalSource,
              'external_id': item.externalId,
              'position': item.position,
              'created_at': item.createdAt.toIso8601String(),
              'updated_at': item.updatedAt.toIso8601String(),
            },
          )
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportMap);
  }

  /// Imports JSON backup atomically
  Future<int> importFromJson(String jsonContent) async {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(jsonContent) as Map<String, dynamic>;
    } catch (e) {
      throw ValidationException('Invalid JSON format: $e');
    }

    final rawSchemas = data['schemas'] as List<dynamic>? ?? [];
    final rawCollections = data['collections'] as List<dynamic>? ?? [];
    final rawItems = data['items'] as List<dynamic>? ?? [];

    int importedCount = 0;

    for (final s in rawSchemas) {
      if (s is Map<String, dynamic>) {
        final schema = Schema.fromJson(s);
        final existing = await _schemaRepo.getSchemaById(schema.id);
        if (existing == null) {
          await _schemaRepo.createSchema(schema);
        }
      }
    }

    for (final c in rawCollections) {
      if (c is Map<String, dynamic>) {
        final collection = Collection.fromJson(c);
        final existing = await _collectionRepo.getCollectionById(collection.id);
        if (existing == null) {
          await _collectionRepo.createCollection(collection);
        }
      }
    }

    for (final raw in rawItems) {
      if (raw is Map<String, dynamic>) {
        final id = raw['id']?.toString() ?? IdGenerator.generate();
        final schemaId = raw['schema_id']?.toString();
        final title = raw['title']?.toString() ?? 'Untitled';
        if (schemaId == null) continue;

        final schema = await _schemaRepo.getSchemaById(schemaId);
        if (schema == null) continue;

        final rawData = raw['data'] as Map<String, dynamic>? ?? {};
        final dynamicFields = FieldValueSerializer.fromRawMap(
          rawData,
          schemaFields: schema.fields,
        );

        final item = Item(
          id: id,
          collectionId: raw['collection_id']?.toString(),
          schemaId: schemaId,
          parentItemId: raw['parent_item_id']?.toString(),
          title: title,
          coverImage: raw['cover_image']?.toString(),
          data: dynamicFields,
          externalSource: raw['external_source']?.toString(),
          externalId: raw['external_id']?.toString(),
          position: (raw['position'] as num?)?.toInt() ?? 0,
          createdAt: DateTime.tryParse(raw['created_at']?.toString() ?? '') ??
              DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final existing = await _itemRepo.getItemById(item.id);
        if (existing == null) {
          await _itemRepo.createItem(item);
          importedCount++;
        }
      }
    }

    _db.notifyItemsChanged();
    _db.notifyCollectionsChanged();
    _db.notifySchemasChanged();

    return importedCount;
  }

  /// Exports items of a collection to CSV
  Future<String> exportToCsv({required String collectionId}) async {
    final collection = await _collectionRepo.getCollectionById(collectionId);
    if (collection == null) {
      throw const NotFoundException('Collection not found');
    }

    final schema = await _schemaRepo.getSchemaById(collection.schemaId);
    if (schema == null) {
      throw const NotFoundException('Schema not found');
    }

    final items = await _itemRepo.getItems(
      collectionId: collectionId,
      includeDeleted: false,
    );

    final List<List<dynamic>> rows = [];

    final List<dynamic> headers = ['ID', 'Title', 'Cover Image'];
    for (final field in schema.fields) {
      headers.add(field.label);
    }
    rows.add(headers);

    for (final item in items) {
      final List<dynamic> row = [item.id, item.title, item.coverImage ?? ''];
      for (final field in schema.fields) {
        final val = item.data[field.key];
        row.add(val != null ? val.toDisplayString() : '');
      }
      rows.add(row);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Imports items from CSV into a collection
  Future<int> importFromCsv({
    required String csvContent,
    required String collectionId,
  }) async {
    final collection = await _collectionRepo.getCollectionById(collectionId);
    if (collection == null) {
      throw const NotFoundException('Collection not found');
    }

    final schema = await _schemaRepo.getSchemaById(collection.schemaId);
    if (schema == null) {
      throw const NotFoundException('Schema not found');
    }

    final List<List<dynamic>> rows;
    try {
      rows = const CsvToListConverter().convert(csvContent);
    } catch (e) {
      throw const ValidationException('Invalid CSV format');
    }

    if (rows.isEmpty || rows.length < 2) {
      return 0;
    }

    final headers = rows.first.map((e) => e.toString().trim()).toList();
    final titleIndex = headers.indexWhere(
      (h) => h.toLowerCase() == 'title' || h.toLowerCase() == 'name',
    );
    if (titleIndex == -1) {
      throw const ValidationException(
        'CSV must have a "Title" or "Name" column header',
      );
    }

    final Map<int, String> fieldIndexToKey = {};
    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].toLowerCase();
      for (final f in schema.fields) {
        if (f.label.toLowerCase() == h || f.key.toLowerCase() == h) {
          fieldIndexToKey[i] = f.key;
          break;
        }
      }
    }

    int imported = 0;
    for (int r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.length <= titleIndex) continue;
      final title = row[titleIndex]?.toString().trim();
      if (title == null || title.isEmpty) continue;

      final Map<String, FieldValue> dynamicData = {};
      for (final entry in fieldIndexToKey.entries) {
        final colIdx = entry.key;
        final fieldKey = entry.value;
        if (colIdx < row.length) {
          final rawCell = row[colIdx];
          final field = schema.fields.firstWhere((f) => f.key == fieldKey);
          if (rawCell != null && rawCell.toString().trim().isNotEmpty) {
            dynamicData[fieldKey] = _parseCell(rawCell.toString(), field.type);
          }
        }
      }

      final item = Item(
        id: IdGenerator.generate(),
        collectionId: collectionId,
        schemaId: schema.id,
        title: title,
        data: dynamicData,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _itemRepo.createItem(item);
      imported++;
    }

    _db.notifyItemsChanged();
    _db.notifyCollectionsChanged();

    return imported;
  }

  FieldValue _parseCell(String val, FieldType type) {
    switch (type) {
      case FieldType.number:
      case FieldType.rating:
        return NumberValue(double.tryParse(val) ?? 0.0);
      case FieldType.boolean:
        return BooleanValue(
          val.toLowerCase() == 'true' ||
              val == '1' ||
              val.toLowerCase() == 'yes',
        );
      case FieldType.multiSelect:
        return MultiSelectValue(
          val
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
        );
      default:
        return TextValue(val);
    }
  }
}
