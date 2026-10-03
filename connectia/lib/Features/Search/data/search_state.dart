part of 'search_cubit.dart';

sealed class SearchState {}

final class SearchInitial extends SearchState {}

final class SearchLoading extends SearchState {}

final class SearchSuggestionsLoaded extends SearchState {
  final List<SearchSuggestion> suggestions;
  SearchSuggestionsLoaded({required this.suggestions});
}

final class SearchEmpty extends SearchState {
  final String query;
  SearchEmpty({required this.query});
}

final class SearchError extends SearchState {
  final String message;
  SearchError({required this.message});
}

final class SearchResultsLoading extends SearchState {}

final class SearchResultsLoaded extends SearchState {
  final List<ProductModel> products;
  final SearchMeta meta;
  final bool isLoadingMore;
  SearchResultsLoaded({
    required this.products,
    required this.meta,
    this.isLoadingMore = false,
  });
}

final class SearchResultsEmpty extends SearchState {
  final String query;
  SearchResultsEmpty({required this.query});
}

final class SearchResultsError extends SearchState {
  final String message;
  final List<ProductModel> previousProducts;
  SearchResultsError({required this.message, this.previousProducts = const []});
}

final class SearchHistoryLoaded extends SearchState {
  final SearchHistory history;
  SearchHistoryLoaded({required this.history});
}
