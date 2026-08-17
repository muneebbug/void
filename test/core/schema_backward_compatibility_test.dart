import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:void_app/core/database/app_database.dart';
import 'package:void_app/core/serialization/field_value_serializer.dart';
import 'package:void_app/features/collections/data/collection_repository.dart';
import 'package:void_app/features/collections/domain/collection.dart';
import 'package:void_app/features/items/data/item_repository.dart';
import 'package:void_app/features/items/domain/field_value.dart';
import 'package:void_app/features/items/domain/item.dart';
import 'package:void_app/features/schemas/data/builtin_schemas.dart';
import 'package:void_app/features/schemas/data/schema_repository.dart';
import 'package:void_app/features/schemas/domain/field_type.dart';
import 'package:void_app/features/schemas/domain/schema_field.dart';

void main() {
  group('Schema Backward Compatibility & Scalability Tests', () {
    test('Simulate upgrading an old database: existing items retain data when new fields are added to schema',
        () async {
      final rawDb = sqlite3.openInMemory();

      // 1. Setup old database structure (e.g. from an older version of the app)
      rawDb.execute('''
        CREATE TABLE schemas (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          icon TEXT,
          is_builtin INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT
        );
        CREATE TABLE schema_fields (
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
          deleted_at TEXT
        );
        CREATE TABLE collections (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          icon TEXT,
          schema_id TEXT NOT NULL,
          position INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT
        );
        CREATE TABLE items (
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
          deleted_at TEXT
        );
      ''');

      const oldDate = '2024-01-01T00:00:00.000Z';

      // Insert an old movie schema with only 2 fields: director, release_year
      rawDb.execute(
        'INSERT INTO schemas VALUES (?, ?, ?, 1, ?, ?, NULL)',
        [BuiltinSchemas.moviesSchemaId, 'Movies', 'movie', oldDate, oldDate],
      );
      rawDb.execute(
        'INSERT INTO schema_fields VALUES (?, ?, ?, ?, ?, ?, 0, 0, ?, ?, NULL)',
        [
          'old_field_director',
          BuiltinSchemas.moviesSchemaId,
          'director',
          'Director',
          'text',
          '{}',
          oldDate,
          oldDate,
        ],
      );
      rawDb.execute(
        'INSERT INTO schema_fields VALUES (?, ?, ?, ?, ?, ?, 0, 1, ?, ?, NULL)',
        [
          'old_field_year',
          BuiltinSchemas.moviesSchemaId,
          'release_year',
          'Release Year',
          'number',
          '{}',
          oldDate,
          oldDate,
        ],
      );

      // Insert an old collection and an old item with only director and release_year in data
      rawDb.execute(
        'INSERT INTO collections VALUES (?, ?, ?, ?, 0, ?, ?, NULL)',
        [
          'col_old',
          'My Movies',
          'movie',
          BuiltinSchemas.moviesSchemaId,
          oldDate,
          oldDate,
        ],
      );
      rawDb.execute(
        'INSERT INTO items VALUES (?, ?, ?, NULL, ?, ?, ?, NULL, NULL, 0, ?, ?, NULL)',
        [
          'item_old_1',
          'col_old',
          BuiltinSchemas.moviesSchemaId,
          'Inception',
          'https://example.com/inception.jpg',
          jsonEncode({'director': 'Christopher Nolan', 'release_year': 2010}),
          oldDate,
          oldDate,
        ],
      );

      // Verify that initially only 2 fields exist in the old database
      final initialFields = rawDb.select(
        'SELECT key FROM schema_fields WHERE schema_id = ?',
        [BuiltinSchemas.moviesSchemaId],
      );
      expect(initialFields.length, equals(2));

      // 2. NOW: The user updates to a newer app version.
      // AppDatabase connects to this database and runs auto-synchronization.
      final db = AppDatabase.inMemory();
      final schemaRepo = SqliteSchemaRepository(db);
      final collectionRepo = SqliteCollectionRepository(db);
      final itemRepo = SqliteItemRepository(db, schemaRepo);

      // Create test collection
      await collectionRepo.createCollection(
        Collection(
          id: 'col_old',
          name: 'My Movies',
          schemaId: BuiltinSchemas.moviesSchemaId,
          icon: 'movie',
          createdAt: DateTime.parse(oldDate),
          updatedAt: DateTime.parse(oldDate),
        ),
      );

      // Verify that all modern fields (rating, runtime, genre, watched, cast, etc.) exist
      final updatedFields = db.rawDb.select(
        'SELECT key, config FROM schema_fields WHERE schema_id = ?',
        [BuiltinSchemas.moviesSchemaId],
      );
      final fieldKeys = updatedFields.map((f) => f['key'] as String).toSet();
      expect(fieldKeys.contains('director'), isTrue);
      expect(fieldKeys.contains('release_year'), isTrue);
      expect(fieldKeys.contains('genre'), isTrue);
      expect(fieldKeys.contains('rating'), isTrue);
      expect(fieldKeys.contains('runtime_minutes'), isTrue);

      // 3. Verify that the rating field config has the updated step: 0.1
      final ratingFieldRow = updatedFields.firstWhere(
        (f) => f['key'] == 'rating',
      );
      final ratingConfig = jsonDecode(ratingFieldRow['config'] as String);
      expect(ratingConfig['step'], equals(0.1));

      // 4. Verify that the existing item is fully backward compatible
      // Insert item into the upgraded database connection
      await itemRepo.createItem(
        Item(
          id: 'item_old_1',
          collectionId: 'col_old',
          schemaId: BuiltinSchemas.moviesSchemaId,
          title: 'Inception',
          coverImage: 'https://example.com/inception.jpg',
          data: {
            'director': const FieldValue.text('Christopher Nolan'),
            'release_year': const FieldValue.number(2010),
          },
          createdAt: DateTime.parse(oldDate),
          updatedAt: DateTime.parse(oldDate),
        ),
      );

      final item = await itemRepo.getItemById('item_old_1');
      expect(item, isNotNull);
      expect(item!.title, equals('Inception'));
      expect(item.getField('director'), equals(const FieldValue.text('Christopher Nolan')));

      // 5. Verify that accessing a new field not present in old data returns empty / nullValue
      final missingValue = item.data['non_existent_key'];
      expect(missingValue == null || missingValue is NullValue, isTrue);

      // 6. Verify updating the item with a new field (e.g. rating) preserves old fields
      final updatedData = Map<String, FieldValue>.from(item.data);
      updatedData['rating'] = const FieldValue.rating(9.5);
      final updatedItem = item.copyWith(data: updatedData);
      await itemRepo.updateItem(updatedItem);

      final reloaded = await itemRepo.getItemById('item_old_1');
      expect(reloaded!.data['rating'], equals(const FieldValue.rating(9.5)));
      expect(reloaded.data['director'], equals(const FieldValue.text('Christopher Nolan')));
      expect(reloaded.data['release_year'], equals(const FieldValue.number(2010)));

      db.close();
      rawDb.dispose();
    });

    test('FieldValueSerializer handles corrupted, missing, and unexpected field formats gracefully', () {
      final fields = [
        SchemaField(
          id: 'f1',
          schemaId: 's1',
          key: 'rating',
          label: 'Rating',
          type: FieldType.rating,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        SchemaField(
          id: 'f2',
          schemaId: 's1',
          key: 'release_year',
          label: 'Year',
          type: FieldType.number,
          position: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        SchemaField(
          id: 'f3',
          schemaId: 's1',
          key: 'genres',
          label: 'Genres',
          type: FieldType.multiSelect,
          position: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // JSON containing strings for numbers, numbers for strings, arrays for single values, unknown keys
      const json = '{"rating": "8.5", "release_year": "1999", "genres": "Sci-Fi", "legacy_custom_key": "old value", "corrupted_null": null}';

      final parsed = FieldValueSerializer.fromJsonString(json, schemaFields: fields);
      expect(parsed['rating'], equals(const FieldValue.rating(8.5)));
      expect(parsed['release_year'], equals(const FieldValue.number(1999.0)));
      expect(parsed['genres'], equals(const FieldValue.multiSelect(['Sci-Fi'])));
      expect(parsed['legacy_custom_key'], equals(const FieldValue.text('old value')));
      expect(parsed['corrupted_null'], equals(const FieldValue.nullValue()));
    });
  });
}
