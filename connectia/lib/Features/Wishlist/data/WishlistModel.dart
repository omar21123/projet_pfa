class WishlistItemModel {
  final int wishListItemId;
  final int wishListId;
  final int productId;
  final String productName;
  final String productImage;
  final double basePrice;
  final String brandName;
  final DateTime? createdAt;

  const WishlistItemModel({
    required this.wishListItemId,
    required this.wishListId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.basePrice,
    required this.brandName,
    this.createdAt,
  });

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    return WishlistItemModel(
      wishListItemId: json['wishListItemId'] as int? ?? 0,
      wishListId: json['wishListId'] as int? ?? 0,
      productId: json['productId'] as int? ?? 0,
      productName: json['productName'] as String? ?? '',
      productImage: json['productImage'] as String? ?? '',
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0,
      brandName: json['brandName'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}

class WishlistModel {
  final int wishListId;
  final String name;
  final bool isDefault;
  final DateTime? createdAt;
  final int itemCount;
  final List<WishlistItemModel> items;

  const WishlistModel({
    required this.wishListId,
    required this.name,
    this.isDefault = false,
    this.createdAt,
    this.itemCount = 0,
    this.items = const [],
  });

  factory WishlistModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return WishlistModel(
      wishListId: json['wishListId'] as int? ?? 0,
      name: json['name'] as String? ?? 'My Wishlist',
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      itemCount: json['itemCount'] as int? ?? 0,
      items: rawItems
          .map((e) => WishlistItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
