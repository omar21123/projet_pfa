import 'package:connectia/Core/api/DioClient.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Register/data/FailureModel.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

enum LoadMoreEndpoint {
  mostSold('/products/most-sold/load-more', 'Les plus vendus'),
  mostViewed('/products/most-viewed/load-more', 'Les plus vus'),
  mostPromoted('/products/most-promoted/load-more', 'En promotion'),
  trending('/products/trending/load-more', 'Tendances'),
  lastActivity('/products/last-activity/load-more', "D'après ton activité"),
  popularInRegion(
      '/products/popular-in-region/load-more', 'Populaire pres de chez toi'),
  newest('/products/new/load-more', 'Nouveautés');

  final String path;
  final String label;
  const LoadMoreEndpoint(this.path, this.label);
}

class PaginatedProducts {
  final List<ProductModel> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  const PaginatedProducts({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.pageSize = 20,
    this.hasMore = false,
  });
}

class ProductRecommendations {
  final List<ProductModel> mostSold;
  final List<ProductModel> mostViewed;
  final List<ProductModel> promotions;
  final List<ProductModel> trending;
  final List<ProductModel> fromYourLastActivity;
  final List<ProductModel> popularInYourRegion;
  final List<ProductModel> newestProducts;

  const ProductRecommendations({
    this.mostSold = const [],
    this.mostViewed = const [],
    this.promotions = const [],
    this.trending = const [],
    this.fromYourLastActivity = const [],
    this.popularInYourRegion = const [],
    this.newestProducts = const [],
  });
}

class SimilarProducts {
  final List<ProductModel> similar;
  final List<ProductModel> similarInBrandsOrModels;
  final List<ProductModel> similarInCategories;

  const SimilarProducts({
    this.similar = const [],
    this.similarInBrandsOrModels = const [],
    this.similarInCategories = const [],
  });
}

class ProductRepo {
  final DioClient _client;
  ProductRepo({required DioClient client}) : _client = client;

  Future<Either<RegisterFailureModel, ProductRecommendations>>
      getRecommendations({
    int limit = 20,
    int? categoryId,
  }) async {
    try {
      await _client.ensureFreshToken();

      final params = <String, dynamic>{'limit': limit};
      if (categoryId != null) params['category_id'] = categoryId;

      final response = await _client.dio.get(
        '/products/recommendations',
        queryParameters: params,
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};

      return Right(ProductRecommendations(
        mostSold: _parseList(data['MostSold']),
        mostViewed: _parseList(data['MostViewed']),
        promotions: _parseList(data['Promotions']),
        trending: _parseList(data['Trending']),
        fromYourLastActivity: _parseList(data['FromYourLastActivity']),
        popularInYourRegion: _parseList(data['PopularInYourRegion']),
        newestProducts: _parseList(data['NewestProducts']),
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

  List<ProductModel> _parseList(dynamic json) {
    if (json == null || json is! List) return [];
    return json
        .map((e) => ProductModel.fromSearchResponse(e as Map<String, dynamic>))
        .toList();
  }

  Future<Either<RegisterFailureModel, SimilarProducts>> getSimilarProducts({
    required int productId,
    int limit = 10,
  }) async {
    try {
      await _client.ensureFreshToken();

      final response = await _client.dio.get(
        '/products/$productId/similar',
        queryParameters: {'limit': limit},
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};

      return Right(SimilarProducts(
        similar: _parseList(data['SimilarProducts']),
        similarInBrandsOrModels: _parseList(data['SimilarInBrandsOrModels']),
        similarInCategories: _parseList(data['SimilarInCategories']),
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

  Future<Either<RegisterFailureModel, PaginatedProducts>> loadMore({
    required LoadMoreEndpoint endpoint,
    int page = 1,
    int pageSize = 20,
    int? categoryId,
  }) async {
    try {
      await _client.ensureFreshToken();

      final params = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (categoryId != null) params['category_id'] = categoryId;

      final response = await _client.dio.get(
        endpoint.path,
        queryParameters: params,
      );

      final body = response.data as Map<String, dynamic>;
      final items =
          _parseList(body['items']);
      final meta = body['meta'] as Map<String, dynamic>? ?? {};

      return Right(PaginatedProducts(
        items: items,
        total: meta['total'] as int? ?? 0,
        page: meta['page'] as int? ?? page,
        pageSize: meta['page_size'] as int? ?? pageSize,
        hasMore: meta['has_more'] as bool? ?? false,
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
