import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Home/data/ProductRepo.dart';

sealed class ProductLoadMoreState {}

final class ProductLoadMoreLoading extends ProductLoadMoreState {}

final class ProductLoadMoreLoaded extends ProductLoadMoreState {
  final List<ProductModel> products;
  final int total;
  final bool hasMore;
  final bool isLoadingMore;

  ProductLoadMoreLoaded({
    this.products = const [],
    this.total = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
  });
}

final class ProductLoadMoreError extends ProductLoadMoreState {
  final String message;
  ProductLoadMoreError({required this.message});
}

class ProductLoadMoreCubit extends Cubit<ProductLoadMoreState> {
  final ProductRepo _repo;
  final LoadMoreEndpoint _endpoint;
  final int? _categoryId;
  int _currentPage = 1;

  ProductLoadMoreCubit({
    required ProductRepo repo,
    required LoadMoreEndpoint endpoint,
    int? categoryId,
  })  : _repo = repo,
        _endpoint = endpoint,
        _categoryId = categoryId,
        super(ProductLoadMoreLoading());

  Future<void> fetchFirstPage() async {
    _currentPage = 1;
    emit(ProductLoadMoreLoading());

    final result = await _repo.loadMore(
      endpoint: _endpoint,
      page: 1,
      categoryId: _categoryId,
    );

    result.fold(
      (failure) =>
          emit(ProductLoadMoreError(message: failure.displayMessage)),
      (page) => emit(ProductLoadMoreLoaded(
        products: page.items,
        total: page.total,
        hasMore: page.hasMore,
      )),
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! ProductLoadMoreLoaded) return;
    if (current.isLoadingMore || !current.hasMore) return;

    emit(ProductLoadMoreLoaded(
      products: current.products,
      total: current.total,
      hasMore: current.hasMore,
      isLoadingMore: true,
    ));

    _currentPage++;

    final result = await _repo.loadMore(
      endpoint: _endpoint,
      page: _currentPage,
      categoryId: _categoryId,
    );

    result.fold(
      (failure) => emit(ProductLoadMoreLoaded(
        products: current.products,
        total: current.total,
        hasMore: false,
      )),
      (page) => emit(ProductLoadMoreLoaded(
        products: [...current.products, ...page.items],
        total: page.total,
        hasMore: page.hasMore,
      )),
    );
  }
}
