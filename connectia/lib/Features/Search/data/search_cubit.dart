import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Search/data/SearchRepo.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final SearchRepo _repo;
  Timer? _debounce;

  String _currentQuery = '';
  int _currentPage = 1;
  int _pageSize = 20;
  bool _isLoadingMore = false;
  SearchHistory? _cachedHistory;

  SearchCubit({required SearchRepo repo})
      : _repo = repo,
        super(SearchInitial());

  // ── History ───────────────────────────────────────────────

  Future<void> fetchHistory() async {
    if (_cachedHistory != null) {
      emit(SearchHistoryLoaded(history: _cachedHistory!));
      return;
    }

    emit(SearchLoading());

    final result = await _repo.getHistory();

    result.fold(
      (failure) => emit(SearchError(message: failure.displayMessage)),
      (history) {
        _cachedHistory = history;
        emit(SearchHistoryLoaded(history: history));
      },
    );
  }

  // ── Suggestions (typing autocomplete) ────────────────────────

  void onQueryChanged(String query) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      fetchHistory();
      return;
    }

    if (query.trim().length < 2) return;

    _debounce = Timer(const Duration(milliseconds: 350), () {
      fetchSuggestions(query.trim());
    });
  }

  Future<void> fetchSuggestions(String query) async {
    if (query.length < 2) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());

    final result = await _repo.getSuggestions(query: query);

    result.fold(
      (failure) => emit(SearchError(message: failure.displayMessage)),
      (suggestions) {
        if (suggestions.isEmpty) {
          emit(SearchEmpty(query: query));
        } else {
          emit(SearchSuggestionsLoaded(suggestions: suggestions));
        }
      },
    );
  }

  // ── Search results (full search page) ────────────────────────

  Future<void> search(String query) async {
    _currentQuery = query;
    _currentPage = 1;

    if (query.trim().isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchResultsLoading());

    final result =
        await _repo.search(query: query, page: 1, pageSize: _pageSize);

    result.fold(
      (failure) => emit(SearchResultsError(message: failure.displayMessage)),
      (data) {
        if (data.products.isEmpty) {
          emit(SearchResultsEmpty(query: query));
        } else {
          emit(SearchResultsLoaded(products: data.products, meta: data.meta));
        }
      },
    );
  }

  Future<void> loadMore() async {
    if (_isLoadingMore) return;

    final currentState = state;
    if (currentState is! SearchResultsLoaded) return;
    if (!currentState.meta.hasMore) return;

    _isLoadingMore = true;
    _currentPage++;

    emit(SearchResultsLoaded(
      products: currentState.products,
      meta: currentState.meta,
      isLoadingMore: true,
    ));

    final result = await _repo.search(
      query: _currentQuery,
      page: _currentPage,
      pageSize: _pageSize,
    );

    _isLoadingMore = false;

    result.fold(
      (failure) {
        emit(SearchResultsError(
          message: failure.displayMessage,
          previousProducts: currentState.products,
        ));
      },
      (data) {
        emit(SearchResultsLoaded(
          products: [...currentState.products, ...data.products],
          meta: data.meta,
        ));
      },
    );
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
