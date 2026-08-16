import 'dart:async';
import 'dart:convert';
import 'package:void_app/core/database/app_database.dart';
import 'package:void_app/core/errors/app_exception.dart';
import 'package:void_app/core/validation/validator.dart';
import 'package:void_app/features/schemas/domain/field_config.dart';
import 'package:void_app/features/schemas/domain/field_type.dart';
import 'package:void_app/features/schemas/domain/schema.dart';
import 'package:void_app/features/schemas/domain/schema_field.dart';

abstract class SchemaRepository {
  Stream<List<Schema>> watchSchemas({bool includeDeleted = false});
  Future<List<Schema>> getSchemas({bool includeDeleted = false});
  Future<Schema?> getSchemaById(String id);
  Future<void> createSchema(Schema schema);
  Future<void> updateSchema(Schema schema);
  Future<void> deleteSchema(String id);
  Future<void> reorderFields(String schemaId, List<String> fieldIdsInOrder);
}

class SqliteSchemaRepository implements SchemaRepository {
  final AppDatabase _db;

  SqliteSchemaRepository(this._db);

  @override
  Stream<List<Schema>> watchSchemas({bool includeDeleted = false}) async* {
    yield await getSchemas(includeDeleted: includeDeleted);
    await for (final _ in _db.onSchemasChanged) {
      yield await getSchemas(includeDeleted: includeDeleted);
    }
  }

  @override
  Future<List<Schema>> getSchemas({bool includeDeleted = false}) async {
    final sql = includeDeleted
        ? 'SELECT * FROM schemas ORDER BY name ASC'
        : 'SELECT * FROM schemas WHERE deleted_at IS NULL ORDER BY name ASC';

    final rows = _db.rawDb.select(sql);
    final List<Schema> schemas = [];
    for (final row in rows) {
      final id = row['id'] as String;
      final fields =
          await _getFieldsForSchema(id, includeDeleted: includeDeleted);
      schemas.add(_mapRowToSchema(row, fields));
    }
    return schemas;
  }

  @override
  Future<Schema?> getSchemaById(String id) async {
    final rows = _db.rawDb.select(
      'SELECT * FROM schemas WHERE id = ? AND deleted_at IS NULL',
      [id],
    );
    if (rows.isEmpty) return null;
    final fields = await _getFieldsForSchema(id, includeDeleted: false);
    return _mapRowToSchema(rows.first, fields);
  }

  Future<List<SchemaField>> _getFieldsForSchema(
    String schemaId, {
    bool includeDeleted = false,
  }) async {
    final sql = includeDeleted
        ? 'SELECT * FROM schema_fields WHERE schema_id = ? ORDER BY position ASC'
        : 'SELECT * FROM schema_fields WHERE schema_id = ? AND deleted_at IS NULL ORDER BY position ASC';

    final rows = _db.rawDb.select(sql, [schemaId]);
    return rows.map(_mapRowToField).toList();
  }

  @override
  Future<void> createSchema(Schema schema) async {
    final validation = Validator.validateSchema(schema);
    if (validation.isInvalid) {
      throw ValidationException(
        'Schema validation failed',
        details: validation.errors.map((e) => e.message).toList(),
      );
    }

    final now = DateTime.now().toIso8601String();
    _db.transaction(() {
      _db.rawDb.execute(
        '''
        INSERT INTO schemas (id, name, icon, is_builtin, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?)
      ''',
        [
          schema.id,
          schema.name,
          schema.icon,
          schema.isBuiltin ? 1 : 0,
          schema.createdAt.toIso8601String(),
          now,
        ],
      );

      for (int i = 0; i < schema.fields.length; i++) {
        final field = schema.fields[i];
        _db.rawDb.execute(
          '''
          INSERT INTO schema_fields (id, schema_id, key, label, type, config, required, position, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
          [
            field.id,
            schema.id,
            field.key,
            field.label,
            field.type.wireName,
            jsonEncode(field.config.toJson()),
            field.required ? 1 : 0,
            i,
            field.createdAt.toIso8601String(),
            now,
          ],
        );
      }
    });

    _db.notifySchemasChanged();
  }

  @override
  Future<void> updateSchema(Schema schema) async {
    final validation = Validator.validateSchema(schema);
    if (validation.isInvalid) {
      throw ValidationException(
        'Schema validation failed',
        details: validation.errors.map((e) => e.message).toList(),
      );
    }

    final now = DateTime.now().toIso8601String();
    _db.transaction(() {
      _db.rawDb.execute(
        'UPDATE schemas SET name = ?, icon = ?, updated_at = ? WHERE id = ?',
        [schema.name, schema.icon, now, schema.id],
      );

      final existingRows = _db.rawDb.select(
        'SELECT id FROM schema_fields WHERE schema_id = ?',
        [schema.id],
      );
      final incomingIds = schema.fields.map((f) => f.id).toSet();

      for (final existing in existingRows) {
        final id = existing['id'] as String;
        if (!incomingIds.contains(id)) {
          _db.rawDb.execute(
            'UPDATE schema_fields SET deleted_at = ?, updated_at = ? WHERE id = ?',
            [now, now, id],
          );
        }
      }

      for (int i = 0; i < schema.fields.length; i++) {
        final field = schema.fields[i];
        _db.rawDb.execute(
          '''
          INSERT INTO schema_fields (id, schema_id, key, label, type, config, required, position, created_at, updated_at, deleted_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)
          ON CONFLICT(id) DO UPDATE SET
            key = excluded.key,
            label = excluded.label,
            type = excluded.type,
            config = excluded.config,
            required = excluded.required,
            position = excluded.position,
            updated_at = excluded.updated_at,
            deleted_at = NULL
        ''',
          [
            field.id,
            schema.id,
            field.key,
            field.label,
            field.type.wireName,
            jsonEncode(field.config.toJson()),
            field.required ? 1 : 0,
            i,
            field.createdAt.toIso8601String(),
            now,
          ],
        );
      }
    });

    _db.notifySchemasChanged();
  }

  @override
  Future<void> deleteSchema(String id) async {
    final existing = await getSchemaById(id);
    if (existing == null) throw NotFoundException('Schema $id not found');
    if (existing.isBuiltin) {
      throw ConflictException(
        'Cannot delete built-in schema "${existing.name}"',
      );
    }

    final now = DateTime.now().toIso8601String();
    _db.transaction(() {
      _db.rawDb.execute(
        'UPDATE schemas SET deleted_at = ?, updated_at = ? WHERE id = ?',
        [now, now, id],
      );
      _db.rawDb.execute(
        'UPDATE schema_fields SET deleted_at = ?, updated_at = ? WHERE schema_id = ?',
        [now, now, id],
      );
    });

    _db.notifySchemasChanged();
  }

  @override
  Future<void> reorderFields(
    String schemaId,
    List<String> fieldIdsInOrder,
  ) async {
    final now = DateTime.now().toIso8601String();
    _db.transaction(() {
      for (int i = 0; i < fieldIdsInOrder.length; i++) {
        _db.rawDb.execute(
          'UPDATE schema_fields SET position = ?, updated_at = ? WHERE id = ?',
          [i, now, fieldIdsInOrder[i]],
        );
      }
    });

    _db.notifySchemasChanged();
  }

  Schema _mapRowToSchema(Map<String, dynamic> row, List<SchemaField> fields) {
    return Schema(
      id: row['id'] as String,
      name: row['name'] as String,
      icon: row['icon'] as String?,
      isBuiltin: (row['is_builtin'] as int? ?? 0) == 1,
      fields: fields,
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      deletedAt: DateTime.tryParse(row['deleted_at']?.toString() ?? ''),
    );
  }

  SchemaField _mapRowToField(Map<String, dynamic> row) {
    FieldConfig config = const NoneFieldConfig();
    final rawConfig = row['config'] as String?;
    if (rawConfig != null && rawConfig.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawConfig);
        if (decoded is Map<String, dynamic>) {
          config = FieldConfig.fromJson(decoded);
        }
      } catch (_) {}
    }

    return SchemaField(
      id: row['id'] as String,
      schemaId: row['schema_id'] as String,
      key: row['key'] as String,
      label: row['label'] as String,
      type: FieldType.fromString(row['type'] as String? ?? 'text'),
      required: (row['required'] as int? ?? 0) == 1,
      position: (row['position'] as int? ?? 0),
      config: config,
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      deletedAt: DateTime.tryParse(row['deleted_at']?.toString() ?? ''),
    );
  }
}
