import 'package:void_app/core/utils/id_generator.dart';
import 'package:void_app/features/items/data/item_repository.dart';
import 'package:void_app/features/items/domain/field_value.dart';
import 'package:void_app/features/items/domain/item.dart';
import 'package:void_app/features/media_search/data/media_api_service.dart';
import 'package:void_app/features/media_search/domain/media_search_result.dart';
import 'package:void_app/features/schemas/data/builtin_schemas.dart';

abstract class MediaSearchRepository {
  Future<List<MediaSearchResult>> searchMedia({
    required String query,
    required String schemaId,
  });

  Future<Item> addItemFromSearchResult({
    required MediaSearchResult result,
    required String collectionId,
    required String schemaId,
  });
}

class DefaultMediaSearchRepository implements MediaSearchRepository {
  final MediaApiService _apiService;
  final ItemRepository _itemRepository;

  DefaultMediaSearchRepository(this._apiService, this._itemRepository);

  @override
  Future<List<MediaSearchResult>> searchMedia({
    required String query,
    required String schemaId,
  }) async {
    if (schemaId == BuiltinSchemas.moviesSchemaId) {
      return _apiService.searchMovies(query);
    } else if (schemaId == BuiltinSchemas.tvShowsSchemaId) {
      return _apiService.searchTvShows(query);
    } else if (schemaId == BuiltinSchemas.booksSchemaId) {
      return _apiService.searchBooks(query);
    } else {
      return _apiService.searchMovies(query);
    }
  }

  @override
  Future<Item> addItemFromSearchResult({
    required MediaSearchResult result,
    required String collectionId,
    required String schemaId,
  }) async {
    final now = DateTime.now();
    final itemId = IdGenerator.generate();
    final Map<String, FieldValue> dynamicData = {};

    if (schemaId == BuiltinSchemas.moviesSchemaId) {
      if (result.creator != null) {
        dynamicData['director'] = TextValue(result.creator!);
      }
      if (result.year != null) {
        final yr = double.tryParse(result.year!) ?? 0.0;
        if (yr > 0) dynamicData['release_year'] = NumberValue(yr);
      }
      if (result.genre != null) {
        dynamicData['genre'] = MultiSelectValue([result.genre!]);
      }
      if (result.rating != null && result.rating! > 0) {
        final rounded = (result.rating! * 10).round() / 10.0;
        dynamicData['rating'] = RatingValue(rounded);
      }
      if (result.runtimeOrPages != null) {
        dynamicData['runtime_minutes'] =
            NumberValue(result.runtimeOrPages!.toDouble());
      }
      if (result.overview != null) {
        dynamicData['overview'] = LongTextValue(result.overview!);
      }
      if (result.coverUrl != null) {
        dynamicData['poster_url'] = ImageValue(result.coverUrl!);
      }
      dynamicData['watched'] = const BooleanValue(false);
    } else if (schemaId == BuiltinSchemas.tvShowsSchemaId) {
      if (result.creator != null) {
        dynamicData['network'] = TextValue(result.creator!);
      }
      if (result.year != null) {
        final yr = double.tryParse(result.year!) ?? 0.0;
        if (yr > 0) dynamicData['first_air_year'] = NumberValue(yr);
      }
      if (result.genre != null) {
        dynamicData['genre'] = MultiSelectValue([result.genre!]);
      }
      if (result.rating != null && result.rating! > 0) {
        final rounded = (result.rating! * 10).round() / 10.0;
        dynamicData['rating'] = RatingValue(rounded);
      }
      if (result.overview != null) {
        dynamicData['overview'] = LongTextValue(result.overview!);
      }
      if (result.coverUrl != null) {
        dynamicData['poster_url'] = ImageValue(result.coverUrl!);
      }
      dynamicData['status'] = const SelectValue('Running');
      dynamicData['watch_state'] = const SelectValue('Plan to Watch');
    } else if (schemaId == BuiltinSchemas.booksSchemaId) {
      if (result.creator != null) {
        dynamicData['author'] = TextValue(result.creator!);
      }
      if (result.year != null) {
        final yr = double.tryParse(result.year!) ?? 0.0;
        if (yr > 0) dynamicData['published_year'] = NumberValue(yr);
      }
      if (result.runtimeOrPages != null) {
        dynamicData['pages'] = NumberValue(result.runtimeOrPages!.toDouble());
      }
      if (result.genre != null) {
        dynamicData['genre'] = SelectValue(result.genre!);
      }
      if (result.rating != null && result.rating! > 0) {
        final rounded = (result.rating! * 10).round() / 10.0;
        dynamicData['rating'] = RatingValue(rounded);
      }
      if (result.overview != null) {
        dynamicData['description'] = LongTextValue(result.overview!);
      }
      if (result.extraIdentifier != null) {
        dynamicData['isbn'] = TextValue(result.extraIdentifier!);
      }
      if (result.coverUrl != null) {
        dynamicData['cover_url'] = ImageValue(result.coverUrl!);
      }
      dynamicData['read_status'] = const SelectValue('Want to Read');
    }

    final item = Item(
      id: itemId,
      collectionId: collectionId,
      schemaId: schemaId,
      title: result.title,
      coverImage: result.coverUrl,
      data: dynamicData,
      externalSource: result.type.name,
      externalId: result.id,
      position: 0,
      createdAt: now,
      updatedAt: now,
    );

    await _itemRepository.createItem(item);
    return item;
  }
}
