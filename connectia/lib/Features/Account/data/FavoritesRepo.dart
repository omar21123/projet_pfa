import 'package:connectia/Core/api/DioClient.dart';
import 'package:connectia/Core/shared/Models/FavoriteModel.dart';
import 'package:connectia/Features/Register/data/FailureModel.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class FavoritesRepo {
  final DioClient _client;
  FavoritesRepo({required DioClient client}) : _client = client;

  Future<Either<RegisterFailureModel, List<FavoriteModel>>>
      getFavorites() async {
    try {
      await _client.ensureFreshToken();

      final response = await _client.dio.get('/favorites');

      final body = response.data as Map<String, dynamic>;
      final list = (body['data'] as List?) ?? [];

      final favorites = list
          .map((e) => FavoriteModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return Right(favorites);
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

  Future<Either<RegisterFailureModel, int>> addFavorite({
    required int productId,
  }) async {
    try {
      await _client.ensureFreshToken();

      final response = await _client.dio.post(
        '/favorites',
        data: {'product_id': productId},
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;

      return Right(data['productLikeId'] as int);
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

  Future<Either<RegisterFailureModel, void>> removeFavorite({
    required int productId,
  }) async {
    try {
      await _client.ensureFreshToken();

      await _client.dio.delete('/favorites/$productId');

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
