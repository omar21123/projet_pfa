import 'package:connectia/Core/api/Env/ApiEnvironment.dart';
import 'package:connectia/Core/storage/TokenStorage.dart';
import 'package:dio/dio.dart';

class DioClient {
  final TokenStorage _tokenStorage;
  late final Dio dio;
  bool _isRefreshing = false;

  DioClient({required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage {
    dio = Dio(BaseOptions(
      baseUrl: ApiEnvironment.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(_AuthInterceptor(
      tokenStorage: _tokenStorage,
      dioClient: this,
    ));
  }

  /// Proactively refreshes the access token before calling public endpoints.
  /// Returns `true` if the token was refreshed or is still valid.
  Future<bool> ensureFreshToken() async {
    return _tryRefreshToken();
  }

  Future<bool> _tryRefreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await Dio().post(
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
    } finally {
      _isRefreshing = false;
    }
  }
}

class _AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final DioClient _dioClient;

  _AuthInterceptor({required TokenStorage tokenStorage, required DioClient dioClient})
      : _tokenStorage = tokenStorage,
        _dioClient = dioClient;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_dioClient._isRefreshing) {
      final refreshed = await _dioClient._tryRefreshToken();
      if (refreshed) {
        final accessToken = await _tokenStorage.getAccessToken();
        err.requestOptions.headers['Authorization'] = 'Bearer $accessToken';

        try {
          final response = await _dioClient.dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } on DioException catch (e) {
          return handler.next(e);
        }
      }
    }
    handler.next(err);
  }
}
