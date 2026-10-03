import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/Navigations/CustomNavigator.dart';
import 'package:connectia/Features/Account/data/FavoritesCubit.dart';
import 'package:connectia/Features/Account/Widgets/Loved%20Products/ProductsLovedAppbar.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductCard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class Productsloved extends StatefulWidget {
  const Productsloved({super.key});

  @override
  State<Productsloved> createState() => _ProductslovedState();
}

class _ProductslovedState extends State<Productsloved> {
  @override
  void initState() {
    super.initState();
    // Fetch favorites on first load
    context.read<FavoritesCubit>().fetchFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              ProductsLovedAppbar(
                itemCount: state is FavoritesLoaded ? state.favorites.length : 0,
              ),
              if (state is FavoritesLoading)
                SliverToBoxAdapter(child: SizedBox(height: 500, child: _buildShimmer()))
              else if (state is FavoritesError)
                SliverToBoxAdapter(child: SizedBox(height: 500, child: _buildError(state.message)))
              else if (state is FavoritesLoaded)
                if (state.favorites.isEmpty)
                  SliverToBoxAdapter(child: SizedBox(height: 500, child: const _EmptyLovedProducts()))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        mainAxisExtent: 290,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final fav = state.favorites[index];
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return ProductCard(
                                key: ValueKey('fav_${fav.productId}'),
                                product: _favoriteToProduct(fav),
                                width: constraints.maxWidth,
                                onTap: () {
                                  CustomNavigator.navigateProductDetailsPage(
                                    fav.productId.toString(),
                                  );
                                },
                                onLikeChanged: (isLiked) {
                                  if (!isLiked) {
                                    context
                                        .read<FavoritesCubit>()
                                        .toggleFavorite(fav.productId);
                                  }
                                },
                              );
                            },
                          );
                        },
                        childCount: state.favorites.length,
                      ),
                    ),
                  )
              else
                const SliverToBoxAdapter(child: SizedBox.shrink()),
            ],
          );
        },
      ),
    );
  }

  /// Convert a FavoriteModel to a ProductModel for ProductCard display
  ProductModel _favoriteToProduct(dynamic fav) {
    final favModel = fav as dynamic;
    final imageUrl = favModel.productImage != null
        ? 'http://localhost${favModel.productImage}'
        : '';
    return ProductModel(
      id: favModel.productId.toString(),
      name: favModel.productName ?? '',
      description: '',
      brand: favModel.brandName ?? '',
      model: '',
      price: favModel.basePrice ?? 0,
      imageUrl: imageUrl,
      totalSales: 0,
      totalLikes: 0,
      totalWishlists: 0,
      isLiked: true,
      isWishlisted: false,
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.softBg(context),
      highlightColor: AppColors.surface(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            mainAxisExtent: 290,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border,
                size: 48, color: AppColors.secondary(context)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondary(context)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<FavoritesCubit>().fetchFavorites();
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLovedProducts extends StatelessWidget {
  const _EmptyLovedProducts();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border,
              size: 72,
              color: AppColors.secondary(context).withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Vous n\'avez encore aimé aucun produit',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.primaryText(context),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Appuyez sur le cœur d\'un article pour le retrouver ici.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.secondary(context),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
