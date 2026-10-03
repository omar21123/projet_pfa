import 'package:connectia/Core/api/DioClient.dart';
import 'package:connectia/Features/Home/data/Models/ProductDetailModel.dart';
import 'package:connectia/Features/Register/data/FailureModel.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class ProductDetailRepo {
  final DioClient _client;
  ProductDetailRepo({required DioClient client}) : _client = client;

  Future<Either<RegisterFailureModel, ProductDetailModel>> getProductInfo({
    required String productId,
    bool fromSearch = false,
    String searchTerm = '',
  }) async {
    try {
      await _client.ensureFreshToken();

      final response = await _client.dio.post(
        '/products/info',
        data: {
          'ProductID': int.tryParse(productId) ?? productId,
          'FromSearch': fromSearch,
          'SearchTerm': searchTerm,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final productData = data['data'] as Map<String, dynamic>;

      return Right(ProductDetailModel.fromJson(productData));
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
