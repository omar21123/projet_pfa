/// Modèle "Produit" pour le feed Home.
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
    );
  }
}
