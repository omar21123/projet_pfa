import 'package:connectia/Core/api/DioClient.dart';
import 'package:connectia/Features/Cart/data/Models/CartItemModel.dart';
import 'package:connectia/Features/Cart/data/Models/CartItemResponseModel.dart';
import 'package:connectia/Features/Register/data/FailureModel.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class CartRepo {
  final DioClient _client;
  CartRepo({required DioClient client}) : _client = client;

  Future<Either<RegisterFailureModel, List<CartItemResponseModel>>>
      getCart() async {
    try {
      await _client.ensureFreshToken();
      final response = await _client.dio.get('/cart');
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as List? ?? [];
      final items = data
          .map((e) =>
              CartItemResponseModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(items);
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        return Left(RegisterFailureModel.fromJson(responseData));
      }
      return Left(RegisterFailureModel.fromException(e));
    } catch (e) {
      return Left(RegisterFailureModel.fromException(e));
    }
  }

  Future<Either<RegisterFailureModel, void>> removeFromCart({
    required int productId,
    required int compositionId,
  }) async {
    try {
      await _client.ensureFreshToken();
      await _client.dio.delete(
        '/cart/items',
        data: {
          'productID': productId,
          'CompositionID': compositionId,
        },
      );
      return const Right(null);
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        return Left(RegisterFailureModel.fromJson(responseData));
      }
      return Left(RegisterFailureModel.fromException(e));
    } catch (e) {
      return Left(RegisterFailureModel.fromException(e));
    }
  }

  Future<Either<RegisterFailureModel, void>> updateQuantity({
    required int cartItemId,
    required int quantity,
  }) async {
    try {
      await _client.ensureFreshToken();
      await _client.dio.patch(
        '/cart/items/quantity',
        data: {
          'CartItemID': cartItemId,
          'Quantity': quantity,
        },
      );
      return const Right(null);
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        return Left(RegisterFailureModel.fromJson(responseData));
      }
      return Left(RegisterFailureModel.fromException(e));
    } catch (e) {
      return Left(RegisterFailureModel.fromException(e));
    }
  }

  Future<Either<RegisterFailureModel, void>> addToCart({
    required AddToCartRequest request,
  }) async {
    try {
      await _client.ensureFreshToken();
      await _client.dio.post(
        '/cart/items',
        data: request.toJson(),
      );
      return const Right(null);
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        return Left(RegisterFailureModel.fromJson(responseData));
      }
      return Left(RegisterFailureModel.fromException(e));
    } catch (e) {
      return Left(RegisterFailureModel.fromException(e));
    }
  }
}
