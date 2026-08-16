import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_app/core/database/app_database.dart';
import 'package:void_app/features/collections/data/collection_repository.dart';
import 'package:void_app/features/import_export/data/import_export_service.dart';
import 'package:void_app/features/items/data/item_repository.dart';
import 'package:void_app/features/media_search/data/media_api_service.dart';
import 'package:void_app/features/media_search/data/media_search_repository.dart';
import 'package:void_app/features/media_search/data/media_sync_service.dart';
import 'package:void_app/features/schemas/data/schema_repository.dart';
import 'package:void_app/features/search/data/local_search_repository.dart';
import 'package:void_app/features/settings/data/settings_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'databaseProvider must be overridden in ProviderScope',
  );
});

final schemaRepositoryProvider = Provider<SchemaRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SqliteSchemaRepository(db);
});

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SqliteCollectionRepository(db);
});

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final schemaRepo = ref.watch(schemaRepositoryProvider);
  return SqliteItemRepository(db, schemaRepo);
});

final localSearchRepositoryProvider = Provider<LocalSearchRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final itemRepo = ref.watch(itemRepositoryProvider);
  final colRepo = ref.watch(collectionRepositoryProvider);
  final schemaRepo = ref.watch(schemaRepositoryProvider);
  return SqliteLocalSearchRepository(db, itemRepo, colRepo, schemaRepo);
});

final mediaApiServiceProvider = Provider<MediaApiService>((ref) {
  return DefaultMediaApiService();
});

final mediaSearchRepositoryProvider = Provider<MediaSearchRepository>((ref) {
  final api = ref.watch(mediaApiServiceProvider);
  final itemRepo = ref.watch(itemRepositoryProvider);
  return DefaultMediaSearchRepository(api, itemRepo);
});

final mediaSyncServiceProvider = Provider<MediaSyncService>((ref) {
  final itemRepo = ref.watch(itemRepositoryProvider);
  final api = ref.watch(mediaApiServiceProvider);
  return DefaultMediaSyncService(itemRepo, api);
});

final importExportServiceProvider = Provider<ImportExportService>((ref) {
  final db = ref.watch(databaseProvider);
  final schemaRepo = ref.watch(schemaRepositoryProvider);
  final colRepo = ref.watch(collectionRepositoryProvider);
  final itemRepo = ref.watch(itemRepositoryProvider);
  return ImportExportService(db, schemaRepo, colRepo, itemRepo);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return FileSettingsRepository();
});
