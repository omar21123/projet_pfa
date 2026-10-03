import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/DI/locator.dart';
import 'package:connectia/Features/Account/Widgets/Orders%20History/OrderCard.dart';
import 'package:connectia/Features/Account/Widgets/Orders%20History/OrderFilterTabs.dart';
import 'package:connectia/Features/Account/Widgets/Orders%20History/OrderHistoryEmptyState.dart';
import 'package:connectia/Features/Account/data/Models/OrderListItem.dart';
import 'package:connectia/Features/Cart/data/OrderRepo.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Page "Historique des commandes".
class Ordershistory extends StatefulWidget {
  const Ordershistory({super.key});

  @override
  State<Ordershistory> createState() => _OrdershistoryState();
}

class _OrdershistoryState extends State<Ordershistory> {
  OrderFilter _selectedFilter = OrderFilter.all;

  List<OrderListItem> _orders = [];
  bool _isLoading = true;
  String? _error;

  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _fetchOrders(reset: true);
  }

  String? get _apiStatusParam {
    switch (_selectedFilter) {
      case OrderFilter.all:
        return null;
      case OrderFilter.inProgress:
        return null; // API doesn't have "inProgress", fetch all and filter client-side
      case OrderFilter.delivered:
        return 'DELIVERED';
    }
  }

  Future<void> _fetchOrders({bool reset = false}) async {
    if (!mounted) return;

    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final result = await locator<OrderRepo>().getOrders(
      status: _apiStatusParam,
      page: _currentPage,
      perPage: _pageSize,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _error = failure.displayMessage;
          _isLoading = false;
          _isLoadingMore = false;
        });
      },
      (response) {
        setState(() {
          if (reset) {
            _orders = response.orders;
          } else {
            _orders = [..._orders, ...response.orders];
          }
          _lastPage = response.meta.lastPage;
          _hasMore = _currentPage < _lastPage;
          _isLoading = false;
          _isLoadingMore = false;
        });
      },
    );
  }

  void _loadMore() {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;
    _fetchOrders();
  }

  void _onFilterChanged(OrderFilter filter) {
    if (filter == _selectedFilter) return;
    setState(() => _selectedFilter = filter);
    _fetchOrders(reset: true);
  }

  List<OrderListItem> get _filteredOrders {
    if (_selectedFilter != OrderFilter.inProgress) return _orders;
    // Client-side filter for "in progress" (PENDING + PREPARING + SHIPPED)
    return _orders.where((o) {
      final code = o.statusCode.toUpperCase();
      return code == 'PENDING' || code == 'PREPARING' || code == 'SHIPPED';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
                onChanged: _onFilterChanged,
              ),
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildShimmer();
    if (_error != null) return _buildError();
    if (_orders.isEmpty) return const OrderHistoryEmptyState();
    return _buildOrderList();
  }

  Widget _buildOrderList() {
    final filtered = _filteredOrders;
    return RefreshIndicator(
      onRefresh: () => _fetchOrders(reset: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: filtered.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filtered.length) {
            // Load more indicator
            if (_isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            // Trigger load more on last item
            WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
            return const SizedBox.shrink();
          }
          final order = filtered[index];
          return OrderCard(
            order: order,
            onTap: () {
              // TODO: naviguer vers OrderDetailsPage.
            },
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.softBg(context),
      highlightColor: AppColors.surface(context),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          height: 160,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.secondary(context)),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondary(context)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchOrders(reset: true),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
