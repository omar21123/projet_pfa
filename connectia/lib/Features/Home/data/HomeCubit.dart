import 'package:bloc/bloc.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Home/data/ProductRepo.dart';

sealed class HomeState {}

final class HomeLoading extends HomeState {}

final class HomeLoaded extends HomeState {
  final List<ProductModel> mostSold;
  final List<ProductModel> mostViewed;
  final List<ProductModel> promotions;
  final List<ProductModel> trending;
  final List<ProductModel> fromYourLastActivity;
  final List<ProductModel> popularInYourRegion;
  final List<ProductModel> newestProducts;

  HomeLoaded({
    this.mostSold = const [],
    this.mostViewed = const [],
    this.promotions = const [],
    this.trending = const [],
    this.fromYourLastActivity = const [],
    this.popularInYourRegion = const [],
    this.newestProducts = const [],
  });
}

final class HomeError extends HomeState {
  final String message;
  HomeError({required this.message});
}

class HomeCubit extends Cubit<HomeState> {
  final ProductRepo _repo;
  HomeCubit({required ProductRepo repo})
      : _repo = repo,
        super(HomeLoading());

  Future<void> fetchRecommendations({int? categoryId}) async {
    emit(HomeLoading());

    final result = await _repo.getRecommendations(
      limit: 20,
      categoryId: categoryId,
    );

    result.fold(
      (failure) => emit(HomeError(message: failure.displayMessage)),
      (recs) => emit(HomeLoaded(
        mostSold: recs.mostSold,
        mostViewed: recs.mostViewed,
        promotions: recs.promotions,
        trending: recs.trending,
        fromYourLastActivity: recs.fromYourLastActivity,
        popularInYourRegion: recs.popularInYourRegion,
        newestProducts: recs.newestProducts,
      )),
    );
  }
}
