import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/DI/locator.dart';
import 'package:connectia/Core/Navigations/CustomNavigator.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Home/data/ProductLoadMoreCubit.dart';
import 'package:connectia/Features/Home/data/ProductRepo.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductCard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class ProductLoadMorePage extends StatelessWidget {
  final LoadMoreEndpoint endpoint;
  final int? categoryId;

  const ProductLoadMorePage({
    super.key,
    required this.endpoint,
    this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductLoadMoreCubit(
        repo: locator<ProductRepo>(),
        endpoint: endpoint,
        categoryId: categoryId,
      )..fetchFirstPage(),
      child: _ProductLoadMoreView(endpoint: endpoint),
    );
  }
}

class _ProductLoadMoreView extends StatefulWidget {
  final LoadMoreEndpoint endpoint;
  const _ProductLoadMoreView({required this.endpoint});

  @override
  State<_ProductLoadMoreView> createState() => _ProductLoadMoreViewState();
}

class _ProductLoadMoreViewState extends State<_ProductLoadMoreView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductLoadMoreCubit>().loadMore();
    }
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
          widget.endpoint.label,
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocBuilder<ProductLoadMoreCubit, ProductLoadMoreState>(
        builder: (context, state) {
          if (state is ProductLoadMoreLoading) {
            return _buildShimmer(context);
          }

          if (state is ProductLoadMoreError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 48, color: AppColors.secondary(context)),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.secondary(context)),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context
                          .read<ProductLoadMoreCubit>()
                          .fetchFirstPage(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is ProductLoadMoreLoaded) {
            if (state.products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 48, color: AppColors.secondary(context)),
                    const SizedBox(height: 12),
                    Text(
                      'Aucun produit',
                      style: TextStyle(color: AppColors.secondary(context)),
                    ),
                  ],
                ),
              );
            }

            return _buildProductGrid(
              context,
              products: state.products,
              isLoadingMore: state.isLoadingMore,
              hasMore: state.hasMore,
              total: state.total,
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildProductGrid(
    BuildContext context, {
    required List<ProductModel> products,
    required bool isLoadingMore,
    required bool hasMore,
    int? total,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 36) / 2;

    return Column(
      children: [
        // ── Count header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Icon(Icons.grid_view_rounded,
                  size: 16, color: AppColors.secondary(context)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  total != null
                      ? '$total produit(s)'
                      : '${products.length} produit(s)',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondary(context),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Product grid ──
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: products.length + (isLoadingMore || hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == products.length) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary(context),
                      ),
                    ),
                  ),
                );
              }

              final product = products[index];
              return ProductCard(
                product: product,
                width: cardWidth,
                onTap: () =>
                    CustomNavigator.navigateProductDetailsPage(product.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.softBg(context),
      highlightColor: AppColors.surface(context),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
