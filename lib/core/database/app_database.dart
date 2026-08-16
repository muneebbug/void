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

  AppDatabase._(this._db, {bool isInMemory = false})
      : _isInMemory = isInMemory {
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

    // Run Migrations: Purge deprecated legacy schemas (notes, tasks, games)
    _db.execute('''
      DELETE FROM schema_fields WHERE schema_id IN ('schema_builtin_notes', 'schema_builtin_tasks', 'schema_builtin_games');
      DELETE FROM items WHERE schema_id IN ('schema_builtin_notes', 'schema_builtin_tasks', 'schema_builtin_games');
      DELETE FROM collections WHERE schema_id IN ('schema_builtin_notes', 'schema_builtin_tasks', 'schema_builtin_games');
      DELETE FROM schemas WHERE id IN ('schema_builtin_notes', 'schema_builtin_tasks', 'schema_builtin_games');
    ''');

    // Seed default schemas and collections
    _seedBuiltins();
  }

  void _seedBuiltins() {
    final now = DateTime.now().toIso8601String();

    // 1. Built-in schemas
    for (final schema in BuiltinSchemas.all) {
      final existing = _db.select(
        'SELECT id FROM schemas WHERE id = ?',
        [schema.id],
      );
      if (existing.isEmpty) {
        _db.execute(
          '''
          INSERT INTO schemas (id, name, icon, is_builtin, created_at, updated_at)
          VALUES (?, ?, ?, 1, ?, ?)
        ''',
          [schema.id, schema.name, schema.icon, now, now],
        );

        for (final field in schema.fields) {
          _db.execute(
            '''
            INSERT INTO schema_fields (id, schema_id, key, label, type, config, required, position, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
            [
              field.id,
              field.schemaId,
              field.key,
              field.label,
              field.type.wireName,
              jsonEncode(field.config.toJson()),
              field.required ? 1 : 0,
              field.position,
              now,
              now,
            ],
          );
        }
      }
    }

    // 2. Default Collections
    final existingCols = _db.select('SELECT id FROM collections');
    if (existingCols.isEmpty) {
      _db.execute(
        '''
        INSERT INTO collections (id, name, icon, schema_id, position, created_at, updated_at)
        VALUES ('col_watchlist', 'Movie Watchlist', 'movie', '${BuiltinSchemas.moviesSchemaId}', 0, ?, ?)
      ''',
        [now, now],
      );

      _db.execute(
        '''
        INSERT INTO collections (id, name, icon, schema_id, position, created_at, updated_at)
        VALUES ('col_tv_shows', 'TV Shows Tracker', 'tv', '${BuiltinSchemas.tvShowsSchemaId}', 1, ?, ?)
      ''',
        [now, now],
      );

      _db.execute(
        '''
        INSERT INTO collections (id, name, icon, schema_id, position, created_at, updated_at)
        VALUES ('col_reading_list', 'Reading List', 'menu_book', '${BuiltinSchemas.booksSchemaId}', 2, ?, ?)
      ''',
        [now, now],
      );
    }

    // 3. Seed Sample Library Media Items (if items table is empty)
    final existingItems = _db.select('SELECT id FROM items LIMIT 1');
    if (existingItems.isEmpty) {
      final allCols = _db.select('SELECT id, schema_id FROM collections');
      final movieColIds = allCols
          .where((r) => r['schema_id'] == BuiltinSchemas.moviesSchemaId)
          .map((r) => r['id'] as String)
          .toList();
      final tvColIds = allCols
          .where((r) => r['schema_id'] == BuiltinSchemas.tvShowsSchemaId)
          .map((r) => r['id'] as String)
          .toList();
      final bookColIds = allCols
          .where((r) => r['schema_id'] == BuiltinSchemas.booksSchemaId)
          .map((r) => r['id'] as String)
          .toList();

      final primaryMovieCol =
          movieColIds.isNotEmpty ? movieColIds.first : 'col_watchlist';
      final primaryTvCol =
          tvColIds.isNotEmpty ? tvColIds.first : 'col_tv_shows';
      final primaryBookCol =
          bookColIds.isNotEmpty ? bookColIds.first : 'col_reading_list';

      final sampleItems = [
        // Books
        {
          'id': 'seed_book_1',
          'col': primaryBookCol,
          'schema': BuiltinSchemas.booksSchemaId,
          'title': 'Total TypeScript',
          'cover':
              'https://images.unsplash.com/photo-1532012164546-f432f2e3edd4?q=80&w=600',
          'data':
              '{"author":"Matt Pocock","progress":"10%","rating":5.0,"status":"Reading"}',
        },
        {
          'id': 'seed_book_2',
          'col': primaryBookCol,
          'schema': BuiltinSchemas.booksSchemaId,
          'title': 'Scope & Closures: You Don\'t Know JS',
          'cover':
              'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?q=80&w=600',
          'data':
              '{"author":"Kyle Simpson","progress":"100%","rating":4.8,"status":"Read"}',
        },
        {
          'id': 'seed_book_3',
          'col': primaryBookCol,
          'schema': BuiltinSchemas.booksSchemaId,
          'title': 'Eloquent JavaScript',
          'cover':
              'https://images.unsplash.com/photo-1512820790803-83ca734da794?q=80&w=600',
          'data':
              '{"author":"Marijn Haverbeke","progress":"1%","rating":4.9,"status":"Reading"}',
        },
        {
          'id': 'seed_book_4',
          'col': primaryBookCol,
          'schema': BuiltinSchemas.booksSchemaId,
          'title': 'TypeScript Deep Dive',
          'cover':
              'https://images.unsplash.com/photo-1589829085413-56de8ae18c73?q=80&w=600',
          'data':
              '{"author":"Basarat Ali Syed","progress":"6%","rating":4.7,"status":"Reading"}',
        },
        // Standalone Book
        {
          'id': 'seed_book_ulysses',
          'col': null,
          'schema': BuiltinSchemas.booksSchemaId,
          'title': 'Ulysses',
          'cover':
              'https://images.unsplash.com/photo-1543002588-bfa74002ed7e?q=80&w=600',
          'data':
              '{"author":"James Joyce","progress":"0%","rating":4.5,"status":"Plan to Read"}',
        },
        // Movies
        {
          'id': 'seed_movie_1',
          'col': primaryMovieCol,
          'schema': BuiltinSchemas.moviesSchemaId,
          'title': 'Inception',
          'cover':
              'https://image.tmdb.org/t/p/w500/ljsZTbVsrQSqZgWeep2B1QiDKuh.jpg',
          'data':
              '{"director":"Christopher Nolan","release_year":2010,"rating":4.9,"watched":true}',
        },
        {
          'id': 'seed_movie_2',
          'col': primaryMovieCol,
          'schema': BuiltinSchemas.moviesSchemaId,
          'title': 'Interstellar',
          'cover':
              'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
          'data':
              '{"director":"Christopher Nolan","release_year":2014,"rating":4.9,"watched":true}',
        },
        {
          'id': 'seed_movie_3',
          'col': primaryMovieCol,
          'schema': BuiltinSchemas.moviesSchemaId,
          'title': 'Dune: Part Two',
          'cover':
              'https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
          'data':
              '{"director":"Denis Villeneuve","release_year":2024,"rating":4.8,"watched":false}',
        },
        {
          'id': 'seed_movie_4',
          'col': primaryMovieCol,
          'schema': BuiltinSchemas.moviesSchemaId,
          'title': 'Oppenheimer',
          'cover':
              'https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
          'data':
              '{"director":"Christopher Nolan","release_year":2023,"rating":4.9,"watched":true}',
        },
        // TV Shows
        {
          'id': 'seed_tv_1',
          'col': primaryTvCol,
          'schema': BuiltinSchemas.tvShowsSchemaId,
          'title': 'Severance',
          'cover':
              'https://image.tmdb.org/t/p/w500/9PFonBhy4cQy7Jz20NpMygczOkv.jpg',
          'data': '{"network":"Apple TV+","rating":4.9,"status":"Watching"}',
        },
        {
          'id': 'seed_tv_2',
          'col': primaryTvCol,
          'schema': BuiltinSchemas.tvShowsSchemaId,
          'title': 'Breaking Bad',
          'cover':
              'https://image.tmdb.org/t/p/w500/ztkUQFLlC19CCMYHW9o1zWhJRNq.jpg',
          'data': '{"network":"AMC","rating":5.0,"status":"Completed"}',
        },
        {
          'id': 'seed_tv_3',
          'col': primaryTvCol,
          'schema': BuiltinSchemas.tvShowsSchemaId,
          'title': 'Dark',
          'cover':
              'https://image.tmdb.org/t/p/w500/apbrbWs8M9lyOpJYU5WXrpFbk1Z.jpg',
          'data': '{"network":"Netflix","rating":4.8,"status":"Completed"}',
        },
        {
          'id': 'seed_tv_4',
          'col': primaryTvCol,
          'schema': BuiltinSchemas.tvShowsSchemaId,
          'title': 'Succession',
          'cover':
              'https://image.tmdb.org/t/p/w500/7T88aoi3gS4vWf9xXvWzR8GzZ2D.jpg',
          'data': '{"network":"HBO","rating":4.9,"status":"Completed"}',
        },
      ];

      // Also populate any secondary movie collection
      for (final colId in movieColIds) {
        if (colId != primaryMovieCol) {
          sampleItems.add({
            'id': 'seed_movie_extra_1_$colId',
            'col': colId,
            'schema': BuiltinSchemas.moviesSchemaId,
            'title': 'Blade Runner 2049',
            'cover':
                'https://image.tmdb.org/t/p/w500/gajva2L0rPYkEWjzgFlBXCAVBE5.jpg',
            'data':
                '{"director":"Denis Villeneuve","release_year":2017,"rating":4.8,"watched":true}',
          });
          sampleItems.add({
            'id': 'seed_movie_extra_2_$colId',
            'col': colId,
            'schema': BuiltinSchemas.moviesSchemaId,
            'title': 'Spider-Man: Across the Spider-Verse',
            'cover':
                'https://image.tmdb.org/t/p/w500/8Vt6mWEReuy4Of61Lnj5Xj704m8.jpg',
            'data':
                '{"director":"Joaquim Dos Santos","release_year":2023,"rating":4.9,"watched":true}',
          });
          sampleItems.add({
            'id': 'seed_movie_extra_3_$colId',
            'col': colId,
            'schema': BuiltinSchemas.moviesSchemaId,
            'title': 'The Dark Knight',
            'cover':
                'https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
            'data':
                '{"director":"Christopher Nolan","release_year":2008,"rating":5.0,"watched":true}',
          });
          sampleItems.add({
            'id': 'seed_movie_extra_4_$colId',
            'col': colId,
            'schema': BuiltinSchemas.moviesSchemaId,
            'title': 'Spirited Away',
            'cover':
                'https://image.tmdb.org/t/p/w500/39wmItIWsg5sZMyRUHLkWBcuVCM.jpg',
            'data':
                '{"director":"Hayao Miyazaki","release_year":2001,"rating":4.9,"watched":true}',
          });
        }
      }

      int pos = 0;
      for (final item in sampleItems) {
        _db.execute(
          '''
          INSERT INTO items (
            id, collection_id, schema_id, title,
            cover_image, data, position, created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
          [
            item['id'],
            item['col'],
            item['schema'],
            item['title'],
            item['cover'],
            item['data'],
            pos++,
            now,
            now,
          ],
        );
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

  void close() {
    _schemasUpdateController.close();
    _collectionsUpdateController.close();
    _itemsUpdateController.close();
    _db.dispose();
  }
}
