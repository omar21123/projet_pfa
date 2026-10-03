import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/DI/locator.dart';
import 'package:connectia/Core/Navigations/CustomNavigator.dart';
import 'package:connectia/Core/widgets/Texts/TextSearchBar.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductCard.dart';
import 'package:connectia/Features/Search/data/SearchRepo.dart';
import 'package:connectia/Features/Search/data/search_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class SearchResultsPage extends StatelessWidget {
  final String initialQuery;

  const SearchResultsPage({super.key, required this.initialQuery});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchCubit(repo: locator<SearchRepo>())
        ..search(initialQuery),
      child: _SearchResultsView(initialQuery: initialQuery),
    );
  }
}

class _SearchResultsView extends StatefulWidget {
  final String initialQuery;
  const _SearchResultsView({required this.initialQuery});

  @override
  State<_SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends State<_SearchResultsView> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchCubit>().loadMore();
    }
  }

  void _onSearch(String query) {
    if (query.trim().length >= 2) {
      context.read<SearchCubit>().search(query.trim());
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
        titleSpacing: 0,
        title: Textsearchbar(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: (value) => setState(() {}),
          onClear: () {
            _controller.clear();
            _onSearch('');
          },
          onSubmitted: _onSearch,
        ),
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          if (state is SearchInitial) {
            return const SizedBox.shrink();
          }

          if (state is SearchResultsLoading) {
            return _buildShimmerGrid(context);
          }

          if (state is SearchResultsError) {
            if (state.previousProducts.isNotEmpty) {
              return _buildProductGrid(
                context,
                products: state.previousProducts,
                isLoadingMore: false,
                hasMore: false,
              );
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 48, color: AppColors.secondary(context)),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.secondary(context)),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is SearchResultsEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 48, color: AppColors.secondary(context)),
                  const SizedBox(height: 12),
                  Text(
                    'Aucun résultat pour "${state.query}"',
                    style: TextStyle(color: AppColors.secondary(context)),
                  ),
                ],
              ),
            );
          }

          if (state is SearchResultsLoaded) {
            return _buildProductGrid(
              context,
              products: state.products,
              isLoadingMore: state.isLoadingMore,
              hasMore: state.meta.hasMore,
              total: state.meta.total,
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
        // ── Result count header ────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Icon(Icons.search_rounded,
                  size: 16, color: AppColors.secondary(context)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  total != null
                      ? '$total résultat(s) pour "${_controller.text}"'
                      : '${products.length} résultat(s)',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondary(context),
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── Product grid ──────────────────────────────────
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
              final query = _controller.text;
              return ProductCard(
                product: product,
                width: cardWidth,
                onTap: () =>
                    CustomNavigator.navigateProductDetailsPage(
                      product.id,
                      searchTerm: query,
                      fromSearch: true,
                    ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerGrid(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 36) / 2;

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
          width: cardWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 90,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 14, width: cardWidth * 0.6, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(
                        height: 10,
                        width: cardWidth * 0.8,
                        color: Colors.white),
                    const SizedBox(height: 4),
                    Container(
                        height: 10,
                        width: cardWidth * 0.5,
                        color: Colors.white),
                    const SizedBox(height: 10),
                    Container(
                        height: 10, width: cardWidth * 0.4, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(
                        height: 16, width: cardWidth * 0.35, color: Colors.white),
                    const SizedBox(height: 10),
                    Container(height: 1, width: double.infinity, color: Colors.white),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                            height: 12,
                            width: 30,
                            color: Colors.white),
                        Container(
                            height: 12,
                            width: 30,
                            color: Colors.white),
                        Container(
                            height: 12,
                            width: 30,
                            color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
