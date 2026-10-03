import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/DI/locator.dart';
import 'package:connectia/Core/Navigations/CustomNavigator.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductCard.dart';
import 'package:connectia/Features/Wishlist/data/WishlistCubit.dart';
import 'package:connectia/Features/Wishlist/data/WishlistModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Page "Liste de souhaits" — shows all wishlists, tap to see items.
class Wishlists extends StatelessWidget {
  const Wishlists({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WishlistCubit(repo: locator())..fetchWishlists(),
      child: const _WishlistsView(),
    );
  }
}

class _WishlistsView extends StatelessWidget {
  const _WishlistsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        title: Text(
          'Mes listes',
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.primaryText(context)),
      ),
      body: BlocBuilder<WishlistCubit, WishlistState>(
        builder: (context, state) {
          if (state is WishlistLoading) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          if (state is WishlistError) {
            return Center(
              child: Text(
                state.message,
                style: TextStyle(color: AppColors.secondary(context)),
              ),
            );
          }

          final wishlists = state is WishlistLoaded
              ? state.wishlists
              : state is WishlistDeleted
                  ? state.wishlists
                  : state is WishlistItemRemoved
                      ? state.wishlists
                      : <WishlistModel>[];

          if (wishlists.isEmpty) {
            return _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: wishlists.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final w = wishlists[index];
              return _WishlistTile(wishlist: w);
            },
          );
        },
      ),
    );
  }
}

class _WishlistTile extends StatelessWidget {
  final WishlistModel wishlist;
  const _WishlistTile({required this.wishlist});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('wishlist-${wishlist.wishListId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.wishlist(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Supprimer la liste'),
            content: Text(
              'Voulez-vous vraiment supprimer « ${wishlist.name} » ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Supprimer',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context
            .read<WishlistCubit>()
            .deleteWishlist(wishListId: wishlist.wishListId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('« ${wishlist.name} » supprimée')),
        );
      },
      child: Material(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<WishlistCubit>(),
                  child: _WishlistDetailPage(wishlist: wishlist),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    wishlist.isDefault
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: AppColors.primary(context),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wishlist.name,
                        style: TextStyle(
                          color: AppColors.primaryText(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${wishlist.itemCount} article${wishlist.itemCount > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: AppColors.secondary(context),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.secondary(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Detail page showing products inside a single wishlist.
class _WishlistDetailPage extends StatelessWidget {
  final WishlistModel wishlist;
  const _WishlistDetailPage({required this.wishlist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        title: Text(
          wishlist.name,
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.primaryText(context)),
      ),
      body: BlocBuilder<WishlistCubit, WishlistState>(
        builder: (context, state) {
          final wishlists = state is WishlistLoaded
              ? state.wishlists
              : state is WishlistDeleted
                  ? state.wishlists
                  : state is WishlistItemRemoved
                      ? state.wishlists
                      : <WishlistModel>[];

          final current = wishlists.firstWhere(
            (w) => w.wishListId == wishlist.wishListId,
            orElse: () => wishlist,
          );

          if (current.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color:
                        AppColors.secondary(context).withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cette liste est vide',
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              mainAxisExtent: 290,
            ),
            itemCount: current.items.length,
            itemBuilder: (context, index) {
              final item = current.items[index];
              final product = ProductModel(
                id: item.productId.toString(),
                name: item.productName,
                description: '',
                imageUrl: item.productImage,
                price: item.basePrice,
                brand: item.brandName,
                model: '',
                totalSales: 0,
                totalLikes: 0,
                totalWishlists: 0,
                isLiked: false,
                isWishlisted: true,
              );

              return LayoutBuilder(
                builder: (context, constraints) {
                  return ProductCard(
                    key: ValueKey('wishlist-item-${item.wishListItemId}'),
                    product: product,
                    width: constraints.maxWidth,
                    onTap: () {
                      CustomNavigator.navigateProductDetailsPage(
                        product.id,
                      );
                    },
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Retirer le produit'),
                          content: Text(
                            'Retirer « ${item.productName} » de cette liste ?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, false),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, true),
                              child: const Text('Retirer',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        context
                            .read<WishlistCubit>()
                            .removeItemFromWishlist(
                              wishListId: wishlist.wishListId,
                              wishListItemId: item.wishListItemId,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '« ${item.productName} » retiré',
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 72,
              color: AppColors.secondary(context).withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune liste de souhaits',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Appuyez sur le signet d\'un article pour créer votre première liste.',
              textAlign: TextAlign.center,
              style: TextStyle(
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
