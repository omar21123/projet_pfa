import 'package:connectia/Core/api/Env/ApiEnvironment.dart';
import 'ProductConfig.dart'; // adapte le chemin selon ton projet

/// Détails d'une promotion appliquée à un produit.
class PromotionDetails {
  final String code;
  final double discountValue;

  const PromotionDetails({required this.code, required this.discountValue});

  factory PromotionDetails.fromJson(Map<String, dynamic> json) =>
      PromotionDetails(
        code: json['Code'] as String? ?? '',
        discountValue: (json['DiscountValue'] as num?)?.toDouble() ?? 0,
      );

  bool get isPercentage => code == 'PERCENTAGE';

  double discountedPrice(double originalPrice) {
    if (isPercentage) {
      return originalPrice - (originalPrice * discountValue / 100);
    }
    return originalPrice - discountValue;
  }
}

/// Modèle "Produit" pour le feed Home + la page détail.
class ProductModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final String brand;
  final String model;
  final int totalSales;
  final int totalLikes;
  final int totalWishlists;
  final bool isLiked;
  final bool isWishlisted;
  final bool hasPromotion;
  final PromotionDetails? promotionDetails;
  final List<String> categories;
  final List<ProductConfig> configs;
  final List<PaymentMethod> allowedPayments;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.brand,
    required this.model,
    required this.totalSales,
    required this.totalLikes,
    required this.totalWishlists,
    required this.isLiked,
    required this.isWishlisted,
    this.hasPromotion = false,
    this.promotionDetails,
    this.categories = const [],
    this.configs = const [],
    this.allowedPayments = const [PaymentMethod.cod, PaymentMethod.online],
  });

  ProductModel copyWith({
    bool? isLiked,
    bool? isWishlisted,
    int? totalLikes,
    int? totalWishlists,
  }) {
    return ProductModel(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrl,
      price: price,
      brand: brand,
      model: model,
      totalSales: totalSales,
      totalLikes: totalLikes ?? this.totalLikes,
      totalWishlists: totalWishlists ?? this.totalWishlists,
      isLiked: isLiked ?? this.isLiked,
      isWishlisted: isWishlisted ?? this.isWishlisted,
      hasPromotion: hasPromotion,
      promotionDetails: promotionDetails,
      categories: categories,
      configs: configs,
      allowedPayments: allowedPayments,
    );
  }

  /// Returns [imageUrl] as-is if it already starts with http(s).
  /// Otherwise prepends the API base URL (without /api).
  String get resolvedImageUrl {
    if (imageUrl.startsWith('http')) return imageUrl;
    final base = ApiEnvironment.baseUrl;
    final trimmedBase = base.endsWith('/api')
        ? base.substring(0, base.length - 4)
        : base;
    return '$trimmedBase/$imageUrl';
  }

  /// Price after discount is applied (if any).
  double get effectivePrice {
    if (hasPromotion && promotionDetails != null) {
      final discounted = promotionDetails!.discountedPrice(price);
      return discounted > 0 ? discounted : price;
    }
    return price;
  }

  /// Discount percentage/amount label.
  String? get promotionLabel {
    if (!hasPromotion || promotionDetails == null) return null;
    final p = promotionDetails!;
    if (p.isPercentage) {
      return '-${p.discountValue.toStringAsFixed(0)}%';
    }
    return '-${p.discountValue.toStringAsFixed(0)} MAD';
  }

  factory ProductModel.fromSearchResponse(Map<String, dynamic> json) {
    final brandJson = json['Brand'] as Map<String, dynamic>?;
    final promoJson = json['PromotionDetails'] as Map<String, dynamic>?;

    return ProductModel(
      id: (json['ProductID'] ?? '').toString(),
      name: json['ProductName'] as String? ?? '',
      description: json['Description'] as String? ?? '',
      imageUrl: json['ProductImage'] as String? ?? '',
      price: (json['Price'] as num?)?.toDouble() ?? 0,
      brand: brandJson?['name'] as String? ?? '',
      model: json['ModelName'] as String? ?? '',
      totalSales: json['TotalOrders'] as int? ?? 0,
      totalLikes: json['TotalLikes'] as int? ?? 0,
      totalWishlists: json['TotalWishlist'] as int? ?? 0,
      isLiked: json['IsLiked'] as bool? ?? false,
      isWishlisted: json['IsWishList'] as bool? ?? false,
      hasPromotion: json['HasPromotion'] as bool? ?? false,
      promotionDetails:
          promoJson != null ? PromotionDetails.fromJson(promoJson) : null,
    );
  }
}
