import 'package:connectia/Core/api/DioClient.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Register/data/FailureModel.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class SearchSuggestion {
  final String text;
  const SearchSuggestion({required this.text});

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) =>
      SearchSuggestion(text: json['text'] as String? ?? '');
}

class SearchMeta {
  final int page;
  final int pageSize;
  final int total;
  final bool hasMore;
  const SearchMeta({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasMore,
  });

  factory SearchMeta.fromJson(Map<String, dynamic> json) => SearchMeta(
        page: json['page'] as int? ?? 1,
        pageSize: json['page_size'] as int? ?? 20,
        total: json['total'] as int? ?? 0,
        hasMore: json['has_more'] as bool? ?? false,
      );
}

class SearchHistory {
  final List<SearchSuggestion> latest;
  final List<SearchSuggestion> famous;
  const SearchHistory({required this.latest, required this.famous});
}

class SearchRepo {
  final DioClient _client;
  SearchRepo({required DioClient client}) : _client = client;

  Future<Either<RegisterFailureModel, List<SearchSuggestion>>> getSuggestions({
    required String query,
    int limit = 10,
  }) async {
    try {
      await _client.ensureFreshToken();

      final response = await _client.dio.get(
        '/search/suggestions',
        queryParameters: {'q': query, 'limit': limit},
      );

      final data = response.data as Map<String, dynamic>;
      final list = (data['data'] as List?) ?? [];

      return Right(
        list
            .map((e) => SearchSuggestion.fromJson(e as Map<String, dynamic>))
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

  Future<
      Either<RegisterFailureModel,
          ({List<ProductModel> products, SearchMeta meta})>> search({
    required String query,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      await _client.ensureFreshToken();

      final response = await _client.dio.get(
        '/search',
        queryParameters: {
          'q': query,
          'page': page,
          'page_size': pageSize,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final list = (data['data'] as List?) ?? [];
      final meta =
          SearchMeta.fromJson(data['meta'] as Map<String, dynamic>? ?? {});

      return Right((
        products: list
            .map((e) =>
                ProductModel.fromSearchResponse(e as Map<String, dynamic>))
            .toList(),
        meta: meta,
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

  Future<Either<RegisterFailureModel, SearchHistory>> getHistory({
    int latestLimit = 10,
    int famousLimit = 10,
  }) async {
    try {
      await _client.ensureFreshToken();

      final response = await _client.dio.get(
        '/search/history',
        queryParameters: {
          'latest_limit': latestLimit,
          'famous_limit': famousLimit,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final latestList = (data['latest'] as List?) ?? [];
      final famousList = (data['famous'] as List?) ?? [];

      return Right(SearchHistory(
        latest: latestList
            .map((e) => SearchSuggestion.fromJson(e as Map<String, dynamic>))
            .toList(),
        famous: famousList
            .map((e) => SearchSuggestion.fromJson(e as Map<String, dynamic>))
            .toList(),
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
