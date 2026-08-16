import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_app/app/app_providers.dart';
import 'package:void_app/features/items/domain/item.dart';
import 'package:void_app/features/media_search/domain/media_search_result.dart';

class MediaSearchState {
  final String query;
  final List<MediaSearchResult> results;
  final bool isLoading;
  final String? errorMessage;
  final bool isAdding;

  const MediaSearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isAdding = false,
  });

  MediaSearchState copyWith({
    String? query,
    List<MediaSearchResult>? results,
    bool? isLoading,
    String? errorMessage,
    bool? isAdding,
  }) {
    return MediaSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isAdding: isAdding ?? this.isAdding,
    );
  }
}

class MediaSearchNotifier extends StateNotifier<MediaSearchState> {
  final Ref _ref;
  final String _schemaId;
  Timer? _debounceTimer;

  MediaSearchNotifier(this._ref, this._schemaId)
      : super(const MediaSearchState());

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void onQueryChanged(String query) {
    state = state.copyWith(query: query);
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], isLoading: false, errorMessage: null);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _executeSearch(query.trim());
    });
  }

  Future<void> _executeSearch(String query) async {
    try {
      final repo = _ref.read(mediaSearchRepositoryProvider);
      final results = await repo.searchMedia(query: query, schemaId: _schemaId);
      state = state.copyWith(
        results: results,
        isLoading: false,
        errorMessage: results.isEmpty ? 'No media found for "$query"' : null,
      );
    } catch (e) {
      state = state.copyWith(
        results: [],
        isLoading: false,
        errorMessage: 'Search error. Check your connection or search query.',
      );
    }
  }

  Future<Item?> addItem(
    MediaSearchResult candidate,
    String collectionId,
  ) async {
    state = state.copyWith(isAdding: true);
    try {
      final repo = _ref.read(mediaSearchRepositoryProvider);
      final item = await repo.addItemFromSearchResult(
        result: candidate,
        collectionId: collectionId,
        schemaId: _schemaId,
      );
      state = state.copyWith(isAdding: false);
      return item;
    } catch (e) {
      state = state.copyWith(
        isAdding: false,
        errorMessage: 'Failed to add item: $e',
      );
      return null;
    }
  }
}

final mediaSearchProvider = StateNotifierProvider.autoDispose
    .family<MediaSearchNotifier, MediaSearchState, String>((ref, schemaId) {
  return MediaSearchNotifier(ref, schemaId);
});
