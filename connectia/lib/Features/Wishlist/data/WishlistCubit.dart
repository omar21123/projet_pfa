import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectia/Features/Wishlist/data/WishlistModel.dart';
import 'package:connectia/Features/Wishlist/data/WishlistRepo.dart';

sealed class WishlistState {}

final class WishlistLoading extends WishlistState {}

final class WishlistLoaded extends WishlistState {
  final List<WishlistModel> wishlists;
  WishlistLoaded({this.wishlists = const []});
}

final class WishlistError extends WishlistState {
  final String message;
  WishlistError({required this.message});
}

final class WishlistItemAdded extends WishlistState {
  final List<WishlistModel> wishlists;
  final String wishlistName;
  WishlistItemAdded({required this.wishlists, required this.wishlistName});
}

final class WishlistDeleted extends WishlistState {
  final List<WishlistModel> wishlists;
  WishlistDeleted({required this.wishlists});
}

final class WishlistItemRemoved extends WishlistState {
  final List<WishlistModel> wishlists;
  WishlistItemRemoved({required this.wishlists});
}

class WishlistCubit extends Cubit<WishlistState> {
  final WishlistRepo _repo;
  WishlistCubit({required WishlistRepo repo})
      : _repo = repo,
        super(WishlistLoading());

  List<WishlistModel> _wishlists = [];
  List<WishlistModel> get wishlists => _wishlists;

  bool isProductInAnyWishlist(int productId) {
    return _wishlists.any(
      (w) => w.items.any((item) => item.productId == productId),
    );
  }

  /// Returns the wishListItemId for the given product across all wishlists, or null.
  int? _findWishListItemId(int productId) {
    for (final w in _wishlists) {
      for (final item in w.items) {
        if (item.productId == productId) return item.wishListItemId;
      }
    }
    return null;
  }

  /// Returns the wishListId that contains the product, or null.
  int? _findWishListId(int productId) {
    for (final w in _wishlists) {
      if (w.items.any((item) => item.productId == productId)) {
        return w.wishListId;
      }
    }
    return null;
  }

  /// Removes the product from whichever wishlist it belongs to.
  Future<void> removeProductFromWishlists(int productId) async {
    final wishListItemId = _findWishListItemId(productId);
    final wishListId = _findWishListId(productId);
    if (wishListItemId == null || wishListId == null) return;

    await removeItemFromWishlist(
      wishListId: wishListId,
      wishListItemId: wishListItemId,
    );
  }

  Future<void> fetchWishlists() async {
    final result = await _repo.getWishlists();
    result.fold(
      (failure) => emit(WishlistError(message: failure.displayMessage)),
      (wishlists) {
        _wishlists = wishlists;
        emit(WishlistLoaded(wishlists: wishlists));
      },
    );
  }

  Future<void> createWishlist(String name) async {
    final result = await _repo.createWishlist(name: name);
    await result.fold(
      (failure) async => emit(WishlistError(message: failure.displayMessage)),
      (wishlist) async {
        final current = state;
        final List<WishlistModel> updated;
        if (current is WishlistLoaded) {
          updated = [...current.wishlists, wishlist];
        } else {
          updated = [wishlist];
        }
        _wishlists = updated;
        emit(WishlistLoaded(wishlists: updated));
      },
    );
  }

  Future<void> addItemToWishlist({
    required int wishListId,
    required int productId,
  }) async {
    final result = await _repo.addItemToWishlist(
      wishListId: wishListId,
      productId: productId,
    );

    result.fold(
      (failure) => emit(WishlistError(message: failure.displayMessage)),
      (_) {
        final current = state;
        if (current is WishlistLoaded) {
          final updated = current.wishlists.map((w) {
            if (w.wishListId == wishListId) {
              return WishlistModel(
                wishListId: w.wishListId,
                name: w.name,
                isDefault: w.isDefault,
                createdAt: w.createdAt,
                itemCount: w.itemCount + 1,
                items: w.items,
              );
            }
            return w;
          }).toList();

          final name = current.wishlists
              .firstWhere((w) => w.wishListId == wishListId)
              .name;
          _wishlists = updated;
          emit(WishlistItemAdded(wishlists: updated, wishlistName: name));
        }
      },
    );
  }

  Future<void> deleteWishlist({required int wishListId}) async {
    final result = await _repo.deleteWishlist(wishListId: wishListId);
    result.fold(
      (failure) => emit(WishlistError(message: failure.displayMessage)),
      (_) {
        final current = state;
        if (current is WishlistLoaded) {
          final updated = current.wishlists
              .where((w) => w.wishListId != wishListId)
              .toList();
          _wishlists = updated;
          emit(WishlistDeleted(wishlists: updated));
        }
      },
    );
  }

  Future<void> removeItemFromWishlist({
    required int wishListId,
    required int wishListItemId,
  }) async {
    final result = await _repo.removeItemFromWishlist(
      wishListItemId: wishListItemId,
    );
    result.fold(
      (failure) => emit(WishlistError(message: failure.displayMessage)),
      (_) {
        final current = state;
        if (current is WishlistLoaded) {
          final updated = current.wishlists.map((w) {
            if (w.wishListId == wishListId) {
              return WishlistModel(
                wishListId: w.wishListId,
                name: w.name,
                isDefault: w.isDefault,
                createdAt: w.createdAt,
                itemCount: w.itemCount - 1,
                items: w.items
                    .where((item) => item.wishListItemId != wishListItemId)
                    .toList(),
              );
            }
            return w;
          }).toList();
          _wishlists = updated;
          emit(WishlistItemRemoved(wishlists: updated));
        }
      },
    );
  }
}
