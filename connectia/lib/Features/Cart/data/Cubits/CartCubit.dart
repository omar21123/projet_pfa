import 'package:connectia/Core/DI/locator.dart';
import 'package:connectia/Features/Cart/data/CartRepo.dart';
import 'package:connectia/Features/Cart/data/Models/CartItemModel.dart';
import 'package:connectia/Features/Cart/data/Models/CartItemResponseModel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── States ───────────────────────────────────────────────────
abstract class CartState {}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<CartItemResponseModel> items;
  CartLoaded({required this.items});

  double get subtotal =>
      items.fold(0, (sum, item) => sum + item.totalPrice);

  double get totalSaved =>
      items.fold(0, (sum, item) => sum + item.savedAmount);
}

class CartError extends CartState {
  final String message;
  CartError({required this.message});
}

class CartActionSuccess extends CartState {
  final String message;
  final List<CartItemResponseModel> items;
  CartActionSuccess({required this.message, required this.items});
}

// ── Cubit ────────────────────────────────────────────────────
class CartCubit extends Cubit<CartState> {
  CartCubit() : super(CartInitial());

  List<CartItemResponseModel> _items = [];
  int get cartCount => _items.length;

  Future<void> fetchCart() async {
    emit(CartLoading());
    final result = await locator<CartRepo>().getCart();
    result.fold(
      (failure) => emit(CartError(message: failure.displayMessage)),
      (items) {
        _items = items;
        emit(CartLoaded(items: items));
      },
    );
  }

  Future<bool> addToCart(AddToCartRequest request) async {
    final result = await locator<CartRepo>().addToCart(request: request);
    return result.fold(
      (failure) {
        emit(CartError(message: failure.displayMessage));
        return false;
      },
      (_) {
        fetchCart();
        return true;
      },
    );
  }

  Future<void> updateQuantity(int cartItemId, int quantity) async {
    final result = await locator<CartRepo>().updateQuantity(
      cartItemId: cartItemId,
      quantity: quantity,
    );
    result.fold(
      (failure) => emit(CartError(message: failure.displayMessage)),
      (_) => fetchCart(),
    );
  }

  Future<void> removeFromCart(int productId, int compositionId) async {
    final result = await locator<CartRepo>().removeFromCart(
      productId: productId,
      compositionId: compositionId,
    );
    result.fold(
      (failure) => emit(CartError(message: failure.displayMessage)),
      (_) => fetchCart(),
    );
  }
}
