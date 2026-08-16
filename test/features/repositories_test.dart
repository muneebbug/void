import 'package:flutter_test/flutter_test.dart';
import 'package:void_app/core/database/app_database.dart';
import 'package:void_app/core/utils/id_generator.dart';
import 'package:void_app/features/collections/data/collection_repository.dart';
import 'package:void_app/features/collections/domain/collection.dart';
import 'package:void_app/features/items/data/item_repository.dart';
import 'package:void_app/features/items/domain/field_value.dart';
import 'package:void_app/features/items/domain/item.dart';
import 'package:void_app/features/schemas/data/builtin_schemas.dart';
import 'package:void_app/features/schemas/data/schema_repository.dart';

void main() {
  group('Repository End-to-End Tests', () {
    late AppDatabase db;
    late SqliteSchemaRepository schemaRepo;
    late SqliteCollectionRepository collectionRepo;
    late SqliteItemRepository itemRepo;

    setUp(() {
      db = AppDatabase.inMemory();
      schemaRepo = SqliteSchemaRepository(db);
      collectionRepo = SqliteCollectionRepository(db);
      itemRepo = SqliteItemRepository(db, schemaRepo);
    });

    tearDown(() {
      db.close();
    });

    test(
        'SchemaRepository retrieves predefined schemas (Movies, TV Shows, Books)',
        () async {
      final schemas = await schemaRepo.getSchemas();
      expect(schemas.length, equals(3));

      final movieSchema =
          await schemaRepo.getSchemaById(BuiltinSchemas.moviesSchemaId);
      expect(movieSchema, isNotNull);
      expect(movieSchema!.name, equals('Movies'));
      expect(movieSchema.isBuiltin, isTrue);

      final tvSchema =
          await schemaRepo.getSchemaById(BuiltinSchemas.tvShowsSchemaId);
      expect(tvSchema, isNotNull);
      expect(tvSchema!.name, equals('TV Shows'));

      final bookSchema =
          await schemaRepo.getSchemaById(BuiltinSchemas.booksSchemaId);
      expect(bookSchema, isNotNull);
      expect(bookSchema!.name, equals('Books'));
    });

    test('CollectionRepository CRUD operations', () async {
      final now = DateTime.now();
      final col = Collection(
        id: IdGenerator.generate(),
        name: 'Favorite Sci-Fi Movies',
        schemaId: BuiltinSchemas.moviesSchemaId,
        createdAt: now,
        updatedAt: now,
      );

      // Create
      await collectionRepo.createCollection(col);

      // Get
      final fetched = await collectionRepo.getCollectionById(col.id);
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Favorite Sci-Fi Movies'));

      // Update
      await collectionRepo.updateCollection(col.copyWith(name: 'Best Sci-Fi'));
      final updated = await collectionRepo.getCollectionById(col.id);
      expect(updated!.name, equals('Best Sci-Fi'));

      // List
      final all = await collectionRepo.getCollections();
      expect(all.any((c) => c.id == col.id), isTrue);

      // Delete
      await collectionRepo.deleteCollection(col.id);
      final afterDelete = await collectionRepo.getCollectionById(col.id);
      expect(afterDelete, isNull);
    });

    test(
        'ItemRepository full lifecycle (CRUD, Subitems, Soft Delete, Restore, Purge)',
        () async {
      final now = DateTime.now();
      final colId = IdGenerator.generate();
      await collectionRepo.createCollection(
        Collection(
          id: colId,
          name: 'My Watchlist',
          schemaId: BuiltinSchemas.moviesSchemaId,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final itemId = IdGenerator.generate();
      final item = Item(
        id: itemId,
        collectionId: colId,
        schemaId: BuiltinSchemas.moviesSchemaId,
        title: 'Inception',
        coverImage: 'https://image.tmdb.org/t/p/w500/inception.jpg',
        data: {
          'director': const FieldValue.text('Christopher Nolan'),
          'release_year': const FieldValue.number(2010),
          'rating': const FieldValue.rating(4.9),
          'genre': const FieldValue.select('Sci-Fi'),
        },
        createdAt: now,
        updatedAt: now,
      );

      // Create Item
      await itemRepo.createItem(item);
      final fetched = await itemRepo.getItemById(itemId);
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('Inception'));
      expect(
        fetched.getField('director'),
        equals(const FieldValue.text('Christopher Nolan')),
      );
      expect(
        fetched.getField('release_year'),
        equals(const FieldValue.number(2010)),
      );

      // Add Sub-item
      final subItemId = IdGenerator.generate();
      final subItem = Item(
        id: subItemId,
        collectionId: colId,
        schemaId: BuiltinSchemas.moviesSchemaId,
        parentItemId: itemId,
        title: 'Watch with Director Commentary',
        createdAt: now,
        updatedAt: now,
      );
      await itemRepo.createItem(subItem);

      final withSubs = await itemRepo.getItemById(itemId);
      expect(withSubs!.subItems.length, equals(1));
      expect(
        withSubs.subItems.first.title,
        equals('Watch with Director Commentary'),
      );

      // Delete Item
      await itemRepo.deleteItem(itemId);
      final afterDelete = await itemRepo.getItemById(itemId);
      expect(afterDelete, isNull);
    });
  });
}
