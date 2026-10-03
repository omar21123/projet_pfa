import 'package:connectia/Core/api/DioClient.dart';
import 'package:connectia/Features/Register/data/FailureModel.dart';
import 'package:connectia/Features/Wishlist/data/WishlistModel.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class WishlistRepo {
  final DioClient _client;
  WishlistRepo({required DioClient client}) : _client = client;

  Future<Either<RegisterFailureModel, List<WishlistModel>>>
      getWishlists() async {
    try {
      final response = await _client.dio.get('/wishlists');
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as List? ?? [];
      return Right(
        data
            .map((e) => WishlistModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
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

  Future<Either<RegisterFailureModel, WishlistModel>> createWishlist({
    String name = 'My Wishlist',
  }) async {
    try {
      final response = await _client.dio.post(
        '/wishlists',
        data: {'name': name},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      return Right(WishlistModel.fromJson(data));
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

  Future<Either<RegisterFailureModel, int>> addItemToWishlist({
    required int wishListId,
    required int productId,
  }) async {
    try {
      final response = await _client.dio.post(
        '/wishlists/$wishListId/items',
        data: {'product_id': productId},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      return Right(data['wishListItemId'] as int? ?? 0);
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

  Future<Either<RegisterFailureModel, void>> deleteWishlist({
    required int wishListId,
  }) async {
    try {
      await _client.dio.delete('/wishlists/$wishListId');
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

  Future<Either<RegisterFailureModel, void>> removeItemFromWishlist({
    required int wishListItemId,
  }) async {
    try {
      await _client.dio.delete(
        '/wishlists/items/$wishListItemId',
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
