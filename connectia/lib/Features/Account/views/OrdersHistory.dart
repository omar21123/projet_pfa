import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Account/Widgets/Orders%20History/OrderCard.dart';
import 'package:connectia/Features/Account/Widgets/Orders%20History/OrderFilterTabs.dart';
import 'package:connectia/Features/Account/Widgets/Orders%20History/OrderHistoryEmptyState.dart';
import 'package:connectia/Features/Account/data/Models/OrderModel.dart';
import 'package:flutter/material.dart';

/// Page "Historique des commandes".
///
/// TODO: `orders` est injecté depuis l'extérieur pour l'instant — brancher
/// sur le vrai service (ex: OrdersService.fetch()) une fois l'API dispo.
/// `_demoOrders` sert de données de démo en attendant — à retirer une fois
/// la vraie source branchée.
class Ordershistory extends StatefulWidget {
  final List<OrderModel> orders;

  const Ordershistory({super.key, this.orders = const []});

  @override
  State<Ordershistory> createState() => _OrdershistoryState();
}

class _OrdershistoryState extends State<Ordershistory> {
  OrderFilter _selectedFilter = OrderFilter.all;

  late final List<OrderModel> _allOrders =
      widget.orders.isNotEmpty ? widget.orders : _demoOrders;

  // ── Données de démo ──────────────────────────────────────────
  // TODO: à retirer une fois branché sur la vraie source (API/provider).
  static final List<OrderModel> _demoOrders = [
    OrderModel(
      id: 'CMD-20458',
      createdDate: DateTime(2026, 7, 22),
      status: OrderStatus.shipped,
      productName: 'Lumix G-Pro X1',
      productImageUrl: 'https://picsum.photos/seed/lumixgprox1/400/400',
      itemCount: 1,
      totalPrice: 1499,
      paymentMethod: PaymentMethod.card,
      livreurName: 'Hamza M.',
      trackingNumber: 'TRK-99218',
    ),
    OrderModel(
      id: 'CMD-20392',
      createdDate: DateTime(2026, 7, 20),
      status: OrderStatus.preparing,
      productName: 'AirPods Pro',
      productImageUrl: 'https://picsum.photos/seed/airpodspro/400/400',
      itemCount: 1,
      totalPrice: 2100,
      paymentMethod: PaymentMethod.cashOnDelivery,
      estimatedDeliveryDate: DateTime(2026, 7, 24),
    ),
    OrderModel(
      id: 'CMD-20150',
      createdDate: DateTime(2026, 7, 15),
      status: OrderStatus.delivered,
      productName: 'iPhone 15 Pro',
      productImageUrl: 'https://picsum.photos/seed/iphone15pro/400/400',
      itemCount: 1,
      totalPrice: 12500,
      paymentMethod: PaymentMethod.card,
      ville: 'Casablanca',
    ),
  ];

  List<OrderModel> get _filteredOrders {
    switch (_selectedFilter) {
      case OrderFilter.all:
        return _allOrders;
      case OrderFilter.inProgress:
        return _allOrders
            .where(
              (o) =>
                  o.status == OrderStatus.pending ||
                  o.status == OrderStatus.preparing ||
                  o.status == OrderStatus.shipped,
            )
            .toList();
      case OrderFilter.delivered:
        return _allOrders
            .where((o) => o.status == OrderStatus.delivered)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryText(context)),
        title: Text(
          'Historique des commandes',
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OrderFilterTabs(
                selected: _selectedFilter,
                onChanged: (filter) => setState(() => _selectedFilter = filter),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const OrderHistoryEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      return OrderCard(
                        order: order,
                        onTap: () {
                          // TODO: naviguer vers OrderDetailsPage.
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}