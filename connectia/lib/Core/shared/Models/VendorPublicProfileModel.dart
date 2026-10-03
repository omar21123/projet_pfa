class VendorPublicProfileModel {
  final String storeName;
  final String? logoUrl;
  final String? bannerUrl;
  final String? note;
  final double rating;
  final int reviewCount;
  final bool identityVerified;
  final bool businessVerified;
  final bool bankVerified;
  final String? description;
  final String? approvedAt;
  final double profileProgress;
  final String? address;
  final String? categories;
  final int totalProducts;
  final int totalSales;

  const VendorPublicProfileModel({
    required this.storeName,
    this.logoUrl,
    this.bannerUrl,
    this.note,
    this.rating = 0,
    this.reviewCount = 0,
    this.identityVerified = false,
    this.businessVerified = false,
    this.bankVerified = false,
    this.description,
    this.approvedAt,
    this.profileProgress = 0,
    this.address,
    this.categories,
    this.totalProducts = 0,
    this.totalSales = 0,
  });

  factory VendorPublicProfileModel.fromJson(Map<String, dynamic> json) {
    return VendorPublicProfileModel(
      storeName: json['StoreName'] as String? ?? '',
      logoUrl: json['LogoURL'] as String?,
      bannerUrl: json['BannerURL'] as String?,
      note: json['Note'] as String?,
      rating: (json['Rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['ReviewCount'] as int? ?? 0,
      identityVerified: json['IdentityVerified'] as bool? ?? false,
      businessVerified: json['BusinessVerified'] as bool? ?? false,
      bankVerified: json['BankVerified'] as bool? ?? false,
      description: json['Description'] as String?,
      approvedAt: json['ApprovedAt'] as String?,
      profileProgress: (json['ProfileProgress'] as num?)?.toDouble() ?? 0,
      address: json['Address'] as String?,
      categories: json['HasProductsInCategories'] as String?,
      totalProducts: json['TotalProducts'] as int? ?? 0,
      totalSales: json['TotalVentes'] as int? ?? 0,
    );
  }
}
