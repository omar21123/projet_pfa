import 'package:connectia/Core/api/DioClient.dart';
import 'package:connectia/Features/Account/data/Models/AddressModel.dart';
import 'package:connectia/Features/Register/data/FailureModel.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class AddressRepo {
  final DioClient _client;
  AddressRepo({required DioClient client}) : _client = client;

  Future<Either<RegisterFailureModel, List<AddressModel>>> getAddresses() async {
    try {
      await _client.ensureFreshToken();
      final response = await _client.dio.get('/addresses');
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as List? ?? [];
      final addresses =
          data.map((e) => AddressModel.fromJson(e as Map<String, dynamic>)).toList();
      return Right(addresses);
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

  Future<Either<RegisterFailureModel, AddressModel>> getAddress({
    required int addressId,
  }) async {
    try {
      await _client.ensureFreshToken();
      final response = await _client.dio.get('/addresses/$addressId');
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      return Right(AddressModel.fromJson(data));
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

  Future<Either<RegisterFailureModel, int>> addAddress({
    required AddressModel address,
  }) async {
    try {
      await _client.ensureFreshToken();
      final response = await _client.dio.post(
        '/addresses',
        data: address.toJson(),
      );
      final body = response.data as Map<String, dynamic>;
      return Right(body['address_id'] as int);
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

  Future<Either<RegisterFailureModel, void>> deleteAddress({
    required int addressId,
  }) async {
    try {
      await _client.ensureFreshToken();
      await _client.dio.delete('/addresses/$addressId');
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

  Future<Either<RegisterFailureModel, void>> setDefaultShipping({
    required int addressId,
  }) async {
    try {
      await _client.ensureFreshToken();
      await _client.dio.patch('/addresses/$addressId/default-shipping');
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

  Future<Either<RegisterFailureModel, void>> setDefaultBilling({
    required int addressId,
  }) async {
    try {
      await _client.ensureFreshToken();
      await _client.dio.patch('/addresses/$addressId/default-billing');
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
