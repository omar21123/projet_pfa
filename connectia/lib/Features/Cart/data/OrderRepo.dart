import 'package:connectia/Core/api/DioClient.dart';
import 'package:connectia/Features/Account/data/Models/OrderListItem.dart';
import 'package:connectia/Features/Register/data/FailureModel.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class PlaceOrderRequest {
  final int addressId;
  final int paymentMethodId;
  final String? notes;

  const PlaceOrderRequest({
    required this.addressId,
    required this.paymentMethodId,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'AddressID': addressId,
        'PaymentMethodID': paymentMethodId,
        if (notes != null && notes!.isNotEmpty) 'Notes': notes,
      };
}

class OrderRepo {
  final DioClient _client;
  OrderRepo({required DioClient client}) : _client = client;

  Future<Either<RegisterFailureModel, OrdersResponse>> getOrders({
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      await _client.ensureFreshToken();
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (status != null) queryParams['status'] = status;

      final response = await _client.dio.get(
        '/orders',
        queryParameters: queryParams,
      );
      final body = response.data as Map<String, dynamic>;
      return Right(OrdersResponse.fromJson(body));
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

  Future<Either<RegisterFailureModel, void>> placeOrderFromCart({
    required PlaceOrderRequest request,
  }) async {
    try {
      await _client.ensureFreshToken();
      await _client.dio.post(
        '/orders/cart',
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
