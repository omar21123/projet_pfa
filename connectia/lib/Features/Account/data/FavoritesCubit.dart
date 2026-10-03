import 'package:connectia/Core/DI/locator.dart';
import 'package:connectia/Core/shared/Models/FavoriteModel.dart';
import 'package:connectia/Features/Account/data/FavoritesRepo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── States ───────────────────────────────────────────────────
abstract class FavoritesState {}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesLoaded extends FavoritesState {
  final List<FavoriteModel> favorites;
  FavoritesLoaded({required this.favorites});
}

class FavoritesError extends FavoritesState {
  final String message;
  FavoritesError({required this.message});
}

class FavoritesToggling extends FavoritesState {
  final int productId;
  FavoritesToggling({required this.productId});
}

// ── Cubit ────────────────────────────────────────────────────
class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit() : super(FavoritesInitial());

  List<FavoriteModel> _favorites = [];
  Set<int> _favoritedProductIds = {};

  List<FavoriteModel> get favorites => _favorites;
  Set<int> get favoritedProductIds => _favoritedProductIds;

  Future<void> fetchFavorites() async {
    emit(FavoritesLoading());
    final result = await locator<FavoritesRepo>().getFavorites();
    result.fold(
      (failure) => emit(FavoritesError(
        message: failure.displayMessage,
      )),
      (favorites) {
        _favorites = favorites;
        _favoritedProductIds = favorites.map((f) => f.productId).toSet();
        emit(FavoritesLoaded(favorites: favorites));
      },
    );
  }

  bool isFavorite(int productId) => _favoritedProductIds.contains(productId);

  Future<void> toggleFavorite(int productId) async {
    final wasFavorite = isFavorite(productId);

    // Optimistic update
    if (wasFavorite) {
      _favoritedProductIds.remove(productId);
    } else {
      _favoritedProductIds.add(productId);
    }
    emit(FavoritesLoaded(favorites: _favorites));

    // API call
    if (wasFavorite) {
      final result = await locator<FavoritesRepo>().removeFavorite(
        productId: productId,
      );
      result.fold(
        (failure) {
          // Revert on failure
          _favoritedProductIds.add(productId);
          emit(FavoritesLoaded(favorites: _favorites));
        },
        (_) {
          _favorites.removeWhere((f) => f.productId == productId);
          emit(FavoritesLoaded(favorites: _favorites));
        },
      );
    } else {
      final result = await locator<FavoritesRepo>().addFavorite(
        productId: productId,
      );
      result.fold(
        (failure) {
          // Revert on failure
          _favoritedProductIds.remove(productId);
          emit(FavoritesLoaded(favorites: _favorites));
        },
        (productLikeId) {
          _favorites.insert(
            0,
            FavoriteModel(
              productLikeId: productLikeId,
              productId: productId,
              productName: '',
              basePrice: 0,
              likedAt: DateTime.now(),
            ),
          );
          emit(FavoritesLoaded(favorites: _favorites));
        },
      );
    }
  }
}
