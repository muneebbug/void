import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:void_app/core/utils/logger.dart';
import 'package:void_app/features/schemas/data/builtin_schemas.dart';

class AppDatabase {
  final Database _db;
  final bool _isInMemory;

  final _schemasUpdateController = StreamController<void>.broadcast();
  final _collectionsUpdateController = StreamController<void>.broadcast();
  final _itemsUpdateController = StreamController<void>.broadcast();

  Stream<void> get onSchemasChanged => _schemasUpdateController.stream;
  Stream<void> get onCollectionsChanged => _collectionsUpdateController.stream;
  Stream<void> get onItemsChanged => _itemsUpdateController.stream;

  AppDatabase._(this._db, {this._isInMemory = false}) {
    _initDatabase();
  }

  static Future<AppDatabase> create() async {
    try {
      final appSupportDir = await getApplicationSupportDirectory();
      if (!await appSupportDir.exists()) {
        await appSupportDir.create(recursive: true);
      }
      final dbPath = p.join(appSupportDir.path, 'void_v1.db');
      final db = sqlite3.open(dbPath);
      return AppDatabase._(db);
    } catch (e) {
      AppLogger.warning(
        'Failed to open disk database, falling back to memory: $e',
      );
      final db = sqlite3.openInMemory();
      return AppDatabase._(db, isInMemory: true);
    }
  }

  factory AppDatabase.inMemory() {
    final db = sqlite3.openInMemory();
    return AppDatabase._(db, isInMemory: true);
  }

  bool get isInMemory => _isInMemory;
  Database get rawDb => _db;

  void notifySchemasChanged() => _schemasUpdateController.add(null);
  void notifyCollectionsChanged() => _collectionsUpdateController.add(null);
  void notifyItemsChanged() => _itemsUpdateController.add(null);

  void _initDatabase() {
    _db.execute('PRAGMA foreign_keys = ON;');

    // Create Schemas Table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS schemas (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT,
        is_builtin INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      );
    ''');

    // Create Schema Fields Table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS schema_fields (
        id TEXT NOT NULL PRIMARY KEY,
        schema_id TEXT NOT NULL,
        key TEXT NOT NULL,
        label TEXT NOT NULL,
        type TEXT NOT NULL,
        config TEXT,
        required INTEGER NOT NULL DEFAULT 0,
        position INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY(schema_id) REFERENCES schemas(id) ON DELETE CASCADE
      );
    ''');

    // Create Collections Table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS collections (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT,
        schema_id TEXT NOT NULL,
        position INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY(schema_id) REFERENCES schemas(id)
      );
    ''');

    // Create Items Table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS items (
        id TEXT NOT NULL PRIMARY KEY,
        collection_id TEXT,
        schema_id TEXT NOT NULL,
        parent_item_id TEXT,
        title TEXT NOT NULL,
        cover_image TEXT,
        data TEXT NOT NULL DEFAULT '{}',
        external_source TEXT,
        external_id TEXT,
        position INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY(collection_id) REFERENCES collections(id) ON DELETE CASCADE,
        FOREIGN KEY(schema_id) REFERENCES schemas(id),
        FOREIGN KEY(parent_item_id) REFERENCES items(id) ON DELETE CASCADE
      );
    ''');

    // Create Performance Indexes
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_items_collection_id ON items(collection_id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_items_schema_id ON items(schema_id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_items_parent_item_id ON items(parent_item_id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_items_deleted_at ON items(deleted_at);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_items_position ON items(position);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_items_updated_at ON items(updated_at);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_collections_schema_id ON collections(schema_id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_collections_deleted_at ON collections(deleted_at);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_schema_fields_schema_id ON schema_fields(schema_id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_schema_fields_deleted_at ON schema_fields(deleted_at);',
    );

    // Seed default schemas and synchronize schema fields seamlessly across app versions
    _seedBuiltins();
  }

  void _seedBuiltins() {
    final now = DateTime.now().toIso8601String();

    // Built-in schemas & fields auto-sync (no default lists or items seeded)
    _syncBuiltinSchemas(now);
  }

  /// Synchronizes built-in schemas and fields across app updates.
  /// Guarantees backward and forward compatibility with existing databases:
  /// - Inserts any newly added schema types
  /// - Inserts any newly added fields to existing schemas
  /// - Updates schema and field configs (e.g. step sizes, new options, labels)
  /// - Leaves existing user data, items, and custom collections 100% intact
  void _syncBuiltinSchemas(String now) {
    for (final schema in BuiltinSchemas.all) {
      final existingSchema = _db.select(
        'SELECT id FROM schemas WHERE id = ?',
        [schema.id],
      );

      if (existingSchema.isEmpty) {
        _db.execute(
          '''
          INSERT INTO schemas (id, name, icon, is_builtin, created_at, updated_at)
          VALUES (?, ?, ?, 1, ?, ?)
        ''',
          [schema.id, schema.name, schema.icon, now, now],
        );
      } else {
        _db.execute(
          '''
          UPDATE schemas
          SET name = ?, icon = ?, is_builtin = 1, updated_at = ?
          WHERE id = ? AND deleted_at IS NULL
        ''',
          [schema.name, schema.icon, now, schema.id],
        );
      }

      for (int i = 0; i < schema.fields.length; i++) {
        final field = schema.fields[i];
        final configJson = jsonEncode(field.config.toJson());

        final existingField = _db.select(
          'SELECT id FROM schema_fields WHERE schema_id = ? AND (id = ? OR key = ?)',
          [schema.id, field.id, field.key],
        );

        if (existingField.isEmpty) {
          _db.execute(
            '''
            INSERT INTO schema_fields (
              id, schema_id, key, label, type, config,
              required, position, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
            [
              field.id,
              field.schemaId,
              field.key,
              field.label,
              field.type.wireName,
              configJson,
              field.required ? 1 : 0,
              field.position,
              now,
              now,
            ],
          );
        } else {
          final existingId = existingField.first['id'] as String;
          _db.execute(
            '''
            UPDATE schema_fields
            SET label = ?, type = ?, config = ?, required = ?,
                position = ?, updated_at = ?, deleted_at = NULL
            WHERE id = ?
          ''',
            [
              field.label,
              field.type.wireName,
              configJson,
              field.required ? 1 : 0,
              field.position,
              now,
              existingId,
            ],
          );
        }
      }
    }
  }

  void transaction(void Function() action) {
    _db.execute('BEGIN TRANSACTION;');
    try {
      action();
      _db.execute('COMMIT;');
    } catch (e) {
      _db.execute('ROLLBACK;');
      rethrow;
    }
  }

  Future<void> close() async {
    await _schemasUpdateController.close();
    await _collectionsUpdateController.close();
    await _itemsUpdateController.close();
    _db.close();
  }
}
