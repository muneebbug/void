import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_app/app/app_providers.dart';
import 'package:void_app/features/search/domain/search_result.dart';

class LocalSearchState {
  final String query;
  final List<SearchResult> results;
  final bool isLoading;

  const LocalSearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
  });

  LocalSearchState copyWith({
    String? query,
    List<SearchResult>? results,
    bool? isLoading,
  }) {
    return LocalSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LocalSearchNotifier extends StateNotifier<LocalSearchState> {
  final Ref _ref;
  Timer? _debounce;

  LocalSearchNotifier(this._ref) : super(const LocalSearchState());

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void search(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);
    _debounce = Timer(const Duration(milliseconds: 150), () async {
      final repo = _ref.read(localSearchRepositoryProvider);
      final results = await repo.search(query);
      state = state.copyWith(results: results, isLoading: false);
    });
  }
}

final localSearchProvider =
    StateNotifierProvider.autoDispose<LocalSearchNotifier, LocalSearchState>(
        (ref) {
  return LocalSearchNotifier(ref);
});

final globalSearchQueryProvider = StateProvider<String>((ref) => '');

