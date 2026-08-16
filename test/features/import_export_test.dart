import 'package:flutter_test/flutter_test.dart';
import 'package:void_app/core/database/app_database.dart';
import 'package:void_app/core/utils/id_generator.dart';
import 'package:void_app/features/collections/data/collection_repository.dart';
import 'package:void_app/features/collections/domain/collection.dart';
import 'package:void_app/features/import_export/data/import_export_service.dart';
import 'package:void_app/features/items/data/item_repository.dart';
import 'package:void_app/features/items/domain/field_value.dart';
import 'package:void_app/features/items/domain/item.dart';
import 'package:void_app/features/schemas/data/builtin_schemas.dart';
import 'package:void_app/features/schemas/data/schema_repository.dart';

void main() {
  group('ImportExportService Tests', () {
    late AppDatabase db;
    late SqliteSchemaRepository schemaRepo;
    late SqliteCollectionRepository collectionRepo;
    late SqliteItemRepository itemRepo;
    late ImportExportService importExportService;

    setUp(() {
      db = AppDatabase.inMemory();
      schemaRepo = SqliteSchemaRepository(db);
      collectionRepo = SqliteCollectionRepository(db);
      itemRepo = SqliteItemRepository(db, schemaRepo);
      importExportService = ImportExportService(
        db,
        schemaRepo,
        collectionRepo,
        itemRepo,
      );
    });

    tearDown(() {
      db.close();
    });

    test('exports database to JSON and re-imports successfully', () async {
      final now = DateTime.now();
      final colId = IdGenerator.generate();
      final col = Collection(
        id: colId,
        name: 'Classic Literature',
        schemaId: BuiltinSchemas.booksSchemaId,
        createdAt: now,
        updatedAt: now,
      );
      await collectionRepo.createCollection(col);

      final itemId = IdGenerator.generate();
      final item = Item(
        id: itemId,
        collectionId: colId,
        schemaId: BuiltinSchemas.booksSchemaId,
        title: '1984',
        data: {
          'author': const FieldValue.text('George Orwell'),
          'pages': const FieldValue.number(328),
          'rating': const FieldValue.rating(5.0),
        },
        createdAt: now,
        updatedAt: now,
      );
      await itemRepo.createItem(item);

      // Export JSON
      final jsonExport = await importExportService.exportToJson();
      expect(jsonExport.contains('Classic Literature'), isTrue);
      expect(jsonExport.contains('1984'), isTrue);
      expect(jsonExport.contains('George Orwell'), isTrue);

      // Create new clean DB and re-import
      final freshDb = AppDatabase.inMemory();
      final freshSchemaRepo = SqliteSchemaRepository(freshDb);
      final freshCollectionRepo = SqliteCollectionRepository(freshDb);
      final freshItemRepo = SqliteItemRepository(freshDb, freshSchemaRepo);
      final freshImportExport = ImportExportService(
        freshDb,
        freshSchemaRepo,
        freshCollectionRepo,
        freshItemRepo,
      );

      final importedCount = await freshImportExport.importFromJson(jsonExport);
      expect(importedCount, greaterThanOrEqualTo(1));

      final importedCol = await freshCollectionRepo.getCollectionById(colId);
      expect(importedCol, isNotNull);
      expect(importedCol!.name, equals('Classic Literature'));

      final importedItem = await freshItemRepo.getItemById(itemId);
      expect(importedItem, isNotNull);
      expect(importedItem!.title, equals('1984'));

      freshDb.close();
    });

    test('exports collection to CSV and re-imports to collection', () async {
      final now = DateTime.now();
      final colId = IdGenerator.generate();
      await collectionRepo.createCollection(
        Collection(
          id: colId,
          name: 'Favorite Sci-Fi Movies',
          schemaId: BuiltinSchemas.moviesSchemaId,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await itemRepo.createItem(
        Item(
          id: IdGenerator.generate(),
          collectionId: colId,
          schemaId: BuiltinSchemas.moviesSchemaId,
          title: 'Interstellar',
          data: {
            'director': const FieldValue.text('Christopher Nolan'),
            'release_year': const FieldValue.number(2014),
          },
          createdAt: now,
          updatedAt: now,
        ),
      );

      final csv = await importExportService.exportToCsv(collectionId: colId);
      expect(csv.contains('Title'), isTrue);
      expect(csv.contains('Interstellar'), isTrue);

      final targetColId = IdGenerator.generate();
      await collectionRepo.createCollection(
        Collection(
          id: targetColId,
          name: 'Imported Movies',
          schemaId: BuiltinSchemas.moviesSchemaId,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final count = await importExportService.importFromCsv(
        csvContent: csv,
        collectionId: targetColId,
      );
      expect(count, equals(1));

      final importedItems = await itemRepo.getItems(collectionId: targetColId);
      expect(importedItems.length, equals(1));
      expect(importedItems.first.title, equals('Interstellar'));
    });
  });
}
