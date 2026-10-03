// Adjust these import paths to match your project structure.
import 'dart:io';

import 'package:connectia/Core/api/Env/ApiEnvironment.dart';
import 'package:connectia/Core/shared/Models/UserModel.dart';
import 'package:connectia/Core/storage/TokenStorage.dart';
import 'package:connectia/Features/Login/data/LoginRequestModel.dart';
import 'package:connectia/Features/Register/data/FailureModel.dart';
import 'package:connectia/Features/Register/data/RegisterRequestModel.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class AuthRepo {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  AuthRepo({required this._dio, required this._tokenStorage});

  @override
  Future<Either<RegisterFailureModel, UserModel>> register({
    required RegisterRequestModel request,
    File? avatar,
  }) async {
    try {
      final fields = <String, dynamic>{};
      request.toJson().forEach((key, value) {
        if (value != null && key != 'avatar') {
          fields[key] = value.toString();
        }
      });

      if (avatar != null) {
        fields['avatar'] = await MultipartFile.fromFile(
          avatar.path,
          filename: avatar.uri.pathSegments.last,
        );
      }

      final response = await _dio.post(
        '${ApiEnvironment.baseUrl}/auth/mobile/register',
        data: FormData.fromMap(fields),
      );

      final data = response.data as Map<String, dynamic>;

      final accessToken = data['access_token'] as String?;
      final refreshToken =
          (data['Refresh_token'] ?? data['refresh_token']) as String?;

      if (accessToken != null && refreshToken != null) {
        await _tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      return Right(UserModel.fromAuthResponse(data));
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(RegisterFailureModel.fromException(e));
    }
  }

  Future<Either<RegisterFailureModel, UserModel>> login({
    required LoginRequestModel request,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiEnvironment.baseUrl}/auth/mobile/login',
        data: request.toJson(),
      );

      final data = response.data as Map<String, dynamic>;

      final accessToken = data['access_token'] as String?;
      final refreshToken =
          (data['Refresh_token'] ?? data['refresh_token']) as String?;

      if (accessToken != null && refreshToken != null) {
        await _tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      return Right(UserModel.fromAuthResponse(data));
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(RegisterFailureModel.fromException(e));
    }
  }

  RegisterFailureModel _mapDioError(DioException e) {
    final responseData = e.response?.data;
    if (responseData is Map<String, dynamic>) {
      return RegisterFailureModel.fromJson(responseData);
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const RegisterFailureModel(
          message: 'Connection timed out. Please try again.',
        );
      case DioExceptionType.connectionError:
        return const RegisterFailureModel(message: 'No internet connection.');
      default:
        return RegisterFailureModel.fromException(e);
    }
  }

  Future<Either<RegisterFailureModel, String>> logout() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();

      if (refreshToken == null) {
        await _tokenStorage.clearAll();
        return const Right('Déconnexion réussie.');
      }

      final response = await _dio.post(
        '${ApiEnvironment.baseUrl}/auth/mobile/logout',
        data: {'refresh_token': refreshToken},
      );

      await _tokenStorage.clearAll();

      final data = response.data as Map<String, dynamic>;
      return Right(data['message'] as String? ?? 'Déconnexion réussie.');
    } on DioException catch (e) {
      await _tokenStorage.clearAll();
      return Left(_mapDioError(e));
    } catch (e) {
      await _tokenStorage.clearAll();
      return Left(RegisterFailureModel.fromException(e));
    }
  }

  Future<bool> refreshTokens() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post(
        '${ApiEnvironment.baseUrl}/auth/mobile/refresh',
        data: {'refresh_token': refreshToken},
      );

      final data = response.data as Map<String, dynamic>;
      final newAccessToken = data['access_token'] as String?;
      final newRefreshToken = data['refresh_token'] as String?;

      if (newAccessToken != null && newRefreshToken != null) {
        await _tokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}
