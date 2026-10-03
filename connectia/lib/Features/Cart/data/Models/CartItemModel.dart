class AddToCartRequest {
  final int productId;
  final bool fromSearch;
  final String? searchTerm;
  final int? compositionId;
  final int quantity;
  final double unitPrice;

  const AddToCartRequest({
    required this.productId,
    this.fromSearch = false,
    this.searchTerm,
    this.compositionId,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'productID': productId,
      'FromSearch': fromSearch,
      if (searchTerm != null && searchTerm!.isNotEmpty)
        'SearchTerm': searchTerm,
      if (compositionId != null) 'CompositionID': compositionId,
      'Quantity': quantity,
      'UnitPrice': unitPrice,
    };
  }
}
