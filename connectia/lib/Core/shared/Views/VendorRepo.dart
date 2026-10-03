import 'package:connectia/Core/api/DioClient.dart';
import 'package:connectia/Core/shared/Models/VendorPublicProfileModel.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Register/data/FailureModel.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class VendorRepo {
  final DioClient _client;
  VendorRepo({required DioClient client}) : _client = client;

  Future<Either<RegisterFailureModel, VendorPublicProfileModel>>
      getPublicProfile({required int vendorProfileId}) async {
    try {
      await _client.ensureFreshToken();

      final response = await _client.dio.get(
        '/vendors/$vendorProfileId/public-profile',
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;

      return Right(VendorPublicProfileModel.fromJson(data));
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

  Future<
      Either<RegisterFailureModel,
          ({List<ProductModel> products, int total, int lastPage})>>
      getVendorProducts({
    required int vendorProfileId,
    int? categoryId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      await _client.ensureFreshToken();

      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (categoryId != null) params['category_id'] = categoryId;

      final response = await _client.dio.get(
        '/products/vendor/$vendorProfileId',
        queryParameters: params,
      );

      final body = response.data as Map<String, dynamic>;
      final list = (body['data'] as List?) ?? [];
      final meta = body['meta'] as Map<String, dynamic>? ?? {};

      final products = list
          .map((e) =>
              ProductModel.fromSearchResponse(e as Map<String, dynamic>))
          .toList();

      return Right((
        products: products,
        total: meta['total'] as int? ?? 0,
        lastPage: meta['last_page'] as int? ?? 1,
      ));
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
