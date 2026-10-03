class FavoriteModel {
  final int productLikeId;
  final int productId;
  final String productName;
  final String? productImage;
  final double basePrice;
  final String? brandName;
  final DateTime? likedAt;

  const FavoriteModel({
    required this.productLikeId,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.basePrice,
    this.brandName,
    this.likedAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      productLikeId: json['productLikeId'] as int,
      productId: json['productId'] as int,
      productName: json['productName'] as String? ?? '',
      productImage: json['productImage'] as String?,
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0,
      brandName: json['brandName'] as String?,
      likedAt: json['likedAt'] != null
          ? DateTime.tryParse(json['likedAt'] as String)
          : null,
    );
  }
}
