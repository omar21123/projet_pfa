import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Home/data/ProductRepo.dart';

sealed class SearchHomeState {}

final class SearchHomeLoading extends SearchHomeState {}

final class SearchHomeLoaded extends SearchHomeState {
  final List<ProductModel> lastSearched;
  final List<ProductModel> newestProducts;

  SearchHomeLoaded({
    this.lastSearched = const [],
    this.newestProducts = const [],
  });
}

final class SearchHomeError extends SearchHomeState {
  final String message;
  SearchHomeError({required this.message});
}

class SearchHomeCubit extends Cubit<SearchHomeState> {
  final ProductRepo _repo;
  SearchHomeCubit({required ProductRepo repo})
      : _repo = repo,
        super(SearchHomeLoading());

  Future<void> fetchRecommendations({int? categoryId}) async {
    emit(SearchHomeLoading());

    final result = await _repo.getRecommendations(limit: 20, categoryId: categoryId);

    result.fold(
      (failure) => emit(SearchHomeError(message: failure.displayMessage)),
      (recs) => emit(SearchHomeLoaded(
        lastSearched: recs.fromYourLastActivity,
        newestProducts: recs.newestProducts,
      )),
    );
  }
}
