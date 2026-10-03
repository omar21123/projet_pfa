class CartItemResponseModel {
  final int cartItemID;
  final int productId;
  final int combinationId;
  final String productName;
  final String productDescription;
  final String brandName;
  final String modelName;
  final double unitPrice;
  final int quantity;
  final int stock;
  final String? sku;
  final String imagePath;
  final List<CombinationDetailModel> combinationDetails;
  final List<String> defaultImages;
  final bool hasPromotion;
  final PromotionModel? promotion;

  const CartItemResponseModel({
    required this.cartItemID,
    required this.productId,
    required this.combinationId,
    required this.productName,
    required this.productDescription,
    required this.brandName,
    required this.modelName,
    required this.unitPrice,
    required this.quantity,
    required this.stock,
    this.sku,
    required this.imagePath,
    this.combinationDetails = const [],
    this.defaultImages = const [],
    this.hasPromotion = false,
    this.promotion,
  });

  double get totalPrice {
    if (hasPromotion && promotion != null) {
      return _discountedPrice * quantity;
    }
    return unitPrice * quantity;
  }

  double get _discountedPrice {
    if (promotion == null) return unitPrice;
    if (promotion!.code == 'PERCENTAGE') {
      return unitPrice * (1 - promotion!.discountValue / 100);
    }
    // FIXED amount
    return unitPrice - promotion!.discountValue;
  }

  double get savedAmount => (unitPrice - _discountedPrice) * quantity;

  factory CartItemResponseModel.fromJson(Map<String, dynamic> json) {
    return CartItemResponseModel(
      cartItemID: json['cartItemID'] as int? ?? 0,
      productId: json['productId'] as int? ?? 0,
      combinationId: json['combinationId'] as int? ?? 0,
      productName: json['productName'] as String? ?? '',
      productDescription: json['productDescription'] as String? ?? '',
      brandName: json['brandName'] as String? ?? '',
      modelName: json['modelName'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      quantity: json['quantity'] as int? ?? 1,
      stock: json['stock'] as int? ?? 0,
      sku: json['sku'] as String?,
      imagePath: json['imagePath'] as String? ?? '',
      combinationDetails: (json['combinationDetails'] as List?)
              ?.map((e) => CombinationDetailModel.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
      defaultImages: (json['defaultImages'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      hasPromotion: json['hasPromotion'] as bool? ?? false,
      promotion: json['promotion'] != null
          ? PromotionModel.fromJson(json['promotion'] as Map<String, dynamic>)
          : null,
    );
  }
}

class CombinationDetailModel {
  final int combinationDetailId;
  final int attributeId;
  final String configName;
  final String optionLabel;
  final int optionId;

  const CombinationDetailModel({
    required this.combinationDetailId,
    required this.attributeId,
    required this.configName,
    required this.optionLabel,
    required this.optionId,
  });

  factory CombinationDetailModel.fromJson(Map<String, dynamic> json) {
    return CombinationDetailModel(
      combinationDetailId: json['combinationDetailId'] as int? ?? 0,
      attributeId: json['attributeId'] as int? ?? 0,
      configName: json['configName'] as String? ?? '',
      optionLabel: json['optionLabel'] as String? ?? '',
      optionId: json['optionId'] as int? ?? 0,
    );
  }
}

class PromotionModel {
  final int promotionId;
  final String name;
  final String description;
  final String startDate;
  final String endDate;
  final double discountValue;
  final String code;
  final String label;

  const PromotionModel({
    required this.promotionId,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.discountValue,
    required this.code,
    required this.label,
  });

  String get discountFormatted {
    if (code == 'PERCENTAGE') {
      return '-${discountValue.toStringAsFixed(0)}%';
    }
    return '-${discountValue.toStringAsFixed(0)} MAD';
  }

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      promotionId: json['promotionId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
      code: json['code'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }
}
