import 'package:void_app/core/database/app_database.dart';
import 'package:void_app/features/collections/data/collection_repository.dart';
import 'package:void_app/features/items/data/item_repository.dart';
import 'package:void_app/features/schemas/data/schema_repository.dart';
import 'package:void_app/features/search/domain/search_result.dart';

abstract class LocalSearchRepository {
  Future<List<SearchResult>> search(String query);
}

class SqliteLocalSearchRepository implements LocalSearchRepository {
  final AppDatabase _db;
  final ItemRepository _itemRepo;
  final CollectionRepository _collectionRepo;
  final SchemaRepository _schemaRepo;

  SqliteLocalSearchRepository(
    this._db,
    this._itemRepo,
    this._collectionRepo,
    this._schemaRepo,
  );

  @override
  Future<List<SearchResult>> search(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final List<SearchResult> results = [];

    // 1. Search Schemas
    final schemas = await _schemaRepo.getSchemas();
    for (final schema in schemas) {
      if (schema.name.toLowerCase().contains(cleanQuery)) {
        results.add(
          SearchResult(
            id: schema.id,
            title: schema.name,
            subtitle: '${schema.fields.length} fields · Schema',
            icon: schema.icon ?? 'schema',
            type: SearchResultType.schema,
            schema: schema,
          ),
        );
      }
    }

    // 2. Search Collections
    final collections = await _collectionRepo.getCollections();
    for (final col in collections) {
      if (col.name.toLowerCase().contains(cleanQuery)) {
        results.add(
          SearchResult(
            id: col.id,
            title: col.name,
            subtitle: '${col.itemCount} items · Collection',
            icon: col.icon ?? 'folder',
            type: SearchResultType.collection,
            collection: col,
          ),
        );
      }
    }

    // 3. Search Items (title + data JSON)
    const sql = '''
      SELECT id FROM items
      WHERE deleted_at IS NULL
        AND (lower(title) LIKE ? OR lower(data) LIKE ?)
      LIMIT 30
    ''';
    final pattern = '%$cleanQuery%';
    final itemRows = _db.rawDb.select(sql, [pattern, pattern]);

    for (final row in itemRows) {
      final id = row['id'] as String;
      final item = await _itemRepo.getItemById(id, includeSubItems: false);
      if (item != null) {
        results.add(
          SearchResult(
            id: item.id,
            title: item.title,
            subtitle: item.getField('genre')?.toDisplayString() ??
                item.getField('author')?.toDisplayString() ??
                item.getField('director')?.toDisplayString() ??
                'Item',
            coverImage: item.coverImage,
            type: SearchResultType.item,
            item: item,
          ),
        );
      }
    }

    return results;
  }
}
