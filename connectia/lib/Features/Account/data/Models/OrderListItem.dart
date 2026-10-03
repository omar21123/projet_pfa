class OrderListItem {
  final int orderId;
  final String orderNumber;
  final String statusCode;
  final String statusName;
  final double total;
  final String currency;
  final int totalItems;
  final int totalVendors;
  final DateTime orderedAt;

  const OrderListItem({
    required this.orderId,
    required this.orderNumber,
    required this.statusCode,
    required this.statusName,
    required this.total,
    required this.currency,
    required this.totalItems,
    required this.totalVendors,
    required this.orderedAt,
  });

  factory OrderListItem.fromJson(Map<String, dynamic> json) {
    return OrderListItem(
      orderId: json['order_id'] as int? ?? 0,
      orderNumber: json['order_number'] as String? ?? '',
      statusCode: json['status_code'] as String? ?? '',
      statusName: json['status_name'] as String? ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'MAD',
      totalItems: json['total_items'] as int? ?? 0,
      totalVendors: json['total_vendors'] as int? ?? 0,
      orderedAt: json['ordered_at'] != null
          ? DateTime.tryParse(json['ordered_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class OrdersPaginationMeta {
  final int total;
  final int page;
  final int pageSize;
  final int lastPage;

  const OrdersPaginationMeta({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.lastPage,
  });

  bool get hasNextPage => page < lastPage;

  factory OrdersPaginationMeta.fromJson(Map<String, dynamic> json) {
    return OrdersPaginationMeta(
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      lastPage: json['last_page'] as int? ?? 1,
    );
  }
}

class OrdersResponse {
  final List<OrderListItem> orders;
  final OrdersPaginationMeta meta;

  const OrdersResponse({required this.orders, required this.meta});

  factory OrdersResponse.fromJson(Map<String, dynamic> json) {
    return OrdersResponse(
      orders: (json['data'] as List?)
              ?.map((e) => OrderListItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      meta: OrdersPaginationMeta.fromJson(
          json['meta'] as Map<String, dynamic>? ?? {}),
    );
  }
}
