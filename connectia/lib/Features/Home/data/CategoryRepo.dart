import 'package:connectia/Core/api/DioClient.dart';
import 'package:connectia/Features/Home/data/Models/CategoryModel.dart';
import 'package:connectia/Features/Register/data/FailureModel.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class CategoryRepo {
  final DioClient _client;
  CategoryRepo({required DioClient client}) : _client = client;

  Future<Either<RegisterFailureModel, List<NavbarCategory>>>
      getNavbarCategories() async {
    try {
      final response = await _client.dio.get('/categories/navbar');

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as List? ?? [];

      return Right(
        data
            .map((e) =>
                NavbarCategory.fromJson(e as Map<String, dynamic>))
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
}
