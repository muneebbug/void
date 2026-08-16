import 'package:void_app/core/utils/logger.dart';
import 'package:void_app/features/items/data/item_repository.dart';
import 'package:void_app/features/items/domain/field_value.dart';
import 'package:void_app/features/items/domain/item.dart';
import 'package:void_app/features/media_search/data/media_api_service.dart';
import 'package:void_app/features/media_search/domain/media_search_result.dart';
import 'package:void_app/features/schemas/data/builtin_schemas.dart';

abstract class MediaSyncService {
  Future<void> syncAllMediaItems();
  Future<void> syncCollectionItems(String collectionId);
}

class DefaultMediaSyncService implements MediaSyncService {
  final ItemRepository _itemRepository;
  final MediaApiService _apiService;
  bool _isSyncing = false;

  DefaultMediaSyncService(this._itemRepository, this._apiService);

  @override
  Future<void> syncAllMediaItems() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final items = await _itemRepository.getItems(includeDeleted: false);
      for (final item in items) {
        await _syncSingleItem(item);
      }
    } catch (e) {
      AppLogger.warning('Background media sync paused: $e', tag: 'MediaSync');
    } finally {
      _isSyncing = false;
    }
  }

  @override
  Future<void> syncCollectionItems(String collectionId) async {
    try {
      final items = await _itemRepository.getItems(
        collectionId: collectionId,
        includeDeleted: false,
      );
      for (final item in items) {
        await _syncSingleItem(item);
      }
    } catch (e) {
      AppLogger.warning(
        'Collection sync paused: $e',
        tag: 'MediaSync',
      );
    }
  }

  Future<void> _syncSingleItem(Item item) async {
    try {
      List<MediaSearchResult> results = [];

      if (item.schemaId == BuiltinSchemas.moviesSchemaId) {
        results = await _apiService.searchMovies(item.title);
      } else if (item.schemaId == BuiltinSchemas.tvShowsSchemaId) {
        results = await _apiService.searchTvShows(item.title);
      } else if (item.schemaId == BuiltinSchemas.booksSchemaId) {
        results = await _apiService.searchBooks(item.title);
      }

      if (results.isEmpty) return;

      // Find closest matching result
      final match = results.firstWhere(
        (r) => r.id == item.externalId,
        orElse: () => results.first,
      );

      bool hasChanges = false;
      final updatedData = Map<String, FieldValue>.from(item.data);

      // Refresh cover if higher resolution or missing
      String? newCover = item.coverImage;
      if ((newCover == null || newCover.isEmpty) && match.coverUrl != null) {
        newCover = match.coverUrl;
        hasChanges = true;
      }

      // Update overview / synopsis if missing
      if (match.overview != null && match.overview!.isNotEmpty) {
        final existingOverview =
            item.data['overview'] ?? item.data['description'];
        if (existingOverview == null ||
            existingOverview.toDisplayString().isEmpty) {
          if (item.schemaId == BuiltinSchemas.booksSchemaId) {
            updatedData['description'] = LongTextValue(match.overview!);
          } else {
            updatedData['overview'] = LongTextValue(match.overview!);
          }
          hasChanges = true;
        }
      }

      if (hasChanges) {
        final updatedItem = item.copyWith(
          coverImage: newCover,
          data: updatedData,
          updatedAt: DateTime.now(),
        );
        await _itemRepository.updateItem(updatedItem);
      }
    } catch (e) {
      // Non-fatal, keep local data intact
    }
  }
}
