import 'package:connectia/Core/api/Env/ApiEnvironment.dart';

class ProductDetailCategory {
  final String name;
  final bool isPrimary;
  const ProductDetailCategory({required this.name, required this.isPrimary});
  factory ProductDetailCategory.fromJson(Map<String, dynamic> json) =>
      ProductDetailCategory(
        name: json['CategoryName'] as String? ?? '',
        isPrimary: json['IsPrimary'] as bool? ?? false,
      );
}

class ProductPaymentMethod {
  final int id;
  final String name;
  final String code;
  final String? iconUrl;
  final double withdrawTax;
  final bool isOnline;
  const ProductPaymentMethod({
    required this.id,
    required this.name,
    required this.code,
    this.iconUrl,
    required this.withdrawTax,
    required this.isOnline,
  });
  factory ProductPaymentMethod.fromJson(Map<String, dynamic> json) =>
      ProductPaymentMethod(
        id: json['PaymentMethodID'] as int? ?? 0,
        name: json['PaymentMethodName'] as String? ?? '',
        code: json['code'] as String? ?? '',
        iconUrl: json['IconURL'] as String?,
        withdrawTax: (json['WithdrawTax'] as num?)?.toDouble() ?? 0,
        isOnline: json['IsOnline'] as bool? ?? false,
      );
}

class ProductDetailConfigOption {
  final int optionId;
  final String label;
  final String value;
  final bool isDefault;
  const ProductDetailConfigOption({
    required this.optionId,
    required this.label,
    required this.value,
    required this.isDefault,
  });
  factory ProductDetailConfigOption.fromJson(Map<String, dynamic> json) =>
      ProductDetailConfigOption(
        optionId: json['OptionID'] as int? ?? 0,
        label: json['OptionLabel'] as String? ?? '',
        value: json['OptionValue'] as String? ?? '',
        isDefault: json['isDefault'] as bool? ?? false,
      );
}

class ProductDetailConfig {
  final int configId;
  final String name;
  final List<ProductDetailConfigOption> options;
  const ProductDetailConfig({
    required this.configId,
    required this.name,
    required this.options,
  });
  factory ProductDetailConfig.fromJson(Map<String, dynamic> json) =>
      ProductDetailConfig(
        configId: json['ConfigID'] as int? ?? 0,
        name: json['ConfigName'] as String? ?? '',
        options: (json['Options'] as List?)
                ?.map((e) => ProductDetailConfigOption.fromJson(
                    e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class ProductCombination {
  final int combinationId;
  final String sku;
  final double price;
  final double compareAtPrice;
  final int stock;
  final String? combinationImage;
  final bool isDefault;
  final int configId;
  final int optionId;
  const ProductCombination({
    required this.combinationId,
    required this.sku,
    required this.price,
    required this.compareAtPrice,
    required this.stock,
    this.combinationImage,
    required this.isDefault,
    required this.configId,
    required this.optionId,
  });
  factory ProductCombination.fromJson(Map<String, dynamic> json) {
    final configs = json['Configs'] as Map<String, dynamic>?;
    return ProductCombination(
      combinationId: json['CombinationID'] as int? ?? 0,
      sku: json['SKU'] as String? ?? '',
      price: (json['CombinationPrice'] as num?)?.toDouble() ?? 0,
      compareAtPrice:
          (json['CompareAtPrice'] as num?)?.toDouble() ?? 0,
      stock: json['CombinationStock'] as int? ?? 0,
      combinationImage: json['CombinationImage'] as String?,
      isDefault: json['IsDefault'] as bool? ?? false,
      configId: configs?['ConfigID'] as int? ?? 0,
      optionId: configs?['OptionID'] as int? ?? 0,
    );
  }
}

class ProductTag {
  final int id;
  final String color;
  final String name;
  const ProductTag(
      {required this.id, required this.color, required this.name});
  factory ProductTag.fromJson(Map<String, dynamic> json) => ProductTag(
        id: json['TagID'] as int? ?? 0,
        color: json['Color'] as String? ?? '#000000',
        name: json['TagName'] as String? ?? '',
      );
}

class ProductPromotion {
  final int promotionId;
  final String name;
  final String description;
  final String discountCode;
  final String discountLabel;
  final double discountValue;
  final double maxDiscountAmount;
  final double minOrderAmount;
  final int usageLimitTotal;
  final int usageCount;
  final int usageLimitPerUser;
  final String startDate;
  final String endDate;
  const ProductPromotion({
    required this.promotionId,
    required this.name,
    required this.description,
    required this.discountCode,
    required this.discountLabel,
    required this.discountValue,
    required this.maxDiscountAmount,
    required this.minOrderAmount,
    required this.usageLimitTotal,
    required this.usageCount,
    required this.usageLimitPerUser,
    required this.startDate,
    required this.endDate,
  });
  bool get isPercentage => discountCode == 'PERCENTAGE';
  String get discountLabelFormatted =>
      isPercentage ? '-${discountValue.toStringAsFixed(0)}%' : '-${discountValue.toStringAsFixed(0)} MAD';
  factory ProductPromotion.fromJson(Map<String, dynamic> json) =>
      ProductPromotion(
        promotionId: json['PromotionID'] as int? ?? 0,
        name: json['Name'] as String? ?? '',
        description: json['Description'] as String? ?? '',
        discountCode: json['DiscountCode'] as String? ?? '',
        discountLabel: json['DiscountLabel'] as String? ?? '',
        discountValue: (json['DiscountValue'] as num?)?.toDouble() ?? 0,
        maxDiscountAmount:
            (json['MaxDiscountAmount'] as num?)?.toDouble() ?? 0,
        minOrderAmount:
            (json['MinOrderAmount'] as num?)?.toDouble() ?? 0,
        usageLimitTotal: json['UsageLimitTotal'] as int? ?? 0,
        usageCount: json['UsageCount'] as int? ?? 0,
        usageLimitPerUser: json['UsageLimitPerUser'] as int? ?? 0,
        startDate: json['StartDate'] as String? ?? '',
        endDate: json['EndDate'] as String? ?? '',
      );
}

class VendorProfile {
  final String id;
  final String storeName;
  final String? bannerUrl;
  final String? logoUrl;
  final String? memberSince;
  final bool identityVerified;
  final bool businessVerified;
  final bool isApproved;
  const VendorProfile({
    required this.id,
    required this.storeName,
    this.bannerUrl,
    this.logoUrl,
    this.memberSince,
    required this.identityVerified,
    required this.businessVerified,
    required this.isApproved,
  });
  factory VendorProfile.fromJson(Map<String, dynamic> json) => VendorProfile(
        id: (json['VendorProfileID'] ?? '').toString(),
        storeName: json['StoreName'] as String? ?? '',
        bannerUrl: json['BannerURL'] as String?,
        logoUrl: json['LogoURL'] as String?,
        memberSince: json['MemberSince'] as String?,
        identityVerified: json['IdentityVerified'] as bool? ?? false,
        businessVerified: json['BusinessVerified'] as bool? ?? false,
        isApproved: json['IsApproved'] as bool? ?? false,
      );
}

/// Full product detail model returned by POST /products/info.
class ProductDetailModel {
  final String id;
  final String name;
  final String description;
  final double basePrice;
  final String brandName;
  final String brandId;
  final String modelName;
  final int stock;
  final int totalSales;
  final int totalLiked;
  final int totalWishlists;
  final bool isLiked;
  final bool isWishlisted;
  final List<ProductDetailCategory> categories;
  final List<ProductPaymentMethod> paymentMethods;
  final List<ProductDetailConfig> configs;
  final List<String> images;
  final List<ProductCombination> combinations;
  final List<ProductTag> tags;
  final bool hasPromotion;
  final ProductPromotion? promotion;
  final VendorProfile? vendor;

  const ProductDetailModel({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.brandName,
    required this.brandId,
    required this.modelName,
    required this.stock,
    required this.totalSales,
    required this.totalLiked,
    required this.totalWishlists,
    this.isLiked = false,
    this.isWishlisted = false,
    required this.categories,
    required this.paymentMethods,
    required this.configs,
    required this.images,
    required this.combinations,
    required this.tags,
    required this.hasPromotion,
    this.promotion,
    this.vendor,
  });

  String get resolvedFirstImage {
    if (images.isEmpty) return '';
    final url = images.first;
    if (url.startsWith('http')) return url;
    final base = ApiEnvironment.baseUrl;
    final trimmedBase =
        base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
    return '$trimmedBase/$url';
  }

  double get effectivePrice {
    if (hasPromotion && promotion != null) {
      final p = promotion!;
      double price;
      if (p.isPercentage) {
        price = basePrice - (basePrice * p.discountValue / 100);
      } else {
        price = basePrice - p.discountValue;
      }
      return price > 0 ? price : 0;
    }
    return basePrice;
  }

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    return ProductDetailModel(
      id: (json['ProductID'] ?? '').toString(),
      name: json['ProductName'] as String? ?? '',
      description: json['ProductDescription'] as String? ?? '',
      basePrice: (json['BasePrice'] as num?)?.toDouble() ?? 0,
      brandName: json['BrandName'] as String? ?? '',
      brandId: (json['BrandID'] ?? '').toString(),
      modelName: json['ModelName'] as String? ?? '',
      stock: json['Stock'] as int? ?? 0,
      totalSales: json['TotalSales'] as int? ?? 0,
      totalLiked: json['TotalLiked'] as int? ?? 0,
      totalWishlists: json['TotalWishlists'] as int? ?? 0,
      isLiked: json['IsLiked'] as bool? ?? false,
      isWishlisted: json['IsWishList'] as bool? ?? false,
      categories: (json['ProductCategories'] as List?)
              ?.map((e) => ProductDetailCategory.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
      paymentMethods: (json['ProductAllowedPayements'] as List?)
              ?.map((e) => ProductPaymentMethod.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
      configs: (json['ProductDetails'] as List?)
              ?.map((e) =>
                  ProductDetailConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      images: (json['DefaultProductImage'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      combinations: (json['ProductOptionsCombiniason'] as List?)
              ?.map((e) => ProductCombination.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
      tags: (json['ProductTags'] as List?)
              ?.map(
                  (e) => ProductTag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      hasPromotion: json['HasPromotion'] as bool? ?? false,
      promotion: json['ProductPromotion'] != null
          ? ProductPromotion.fromJson(
              json['ProductPromotion'] as Map<String, dynamic>)
          : null,
      vendor: json['VendorProfile'] != null
          ? VendorProfile.fromJson(
              json['VendorProfile'] as Map<String, dynamic>)
          : null,
    );
  }
}
