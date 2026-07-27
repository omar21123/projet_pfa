import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Account/Widgets/Loved%20Products/ProductsLovedAppbar.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductCard.dart';
import 'package:flutter/material.dart';

/// Page "Produits aimés" — liste des produits likés (cœur), distincte de
/// la liste de souhaits (bookmark).
///
/// TODO: `items` est injecté depuis l'extérieur pour l'instant — brancher
/// sur le vrai service/provider (ex: LikedProductsService.fetch()) une fois
/// l'API dispo. `_demoLovedProducts` sert de données de démo en attendant —
/// à retirer une fois la vraie source branchée.
class Productsloved extends StatefulWidget {
  final List<ProductModel> items;

  const Productsloved({super.key, this.items = const []});

  @override
  State<Productsloved> createState() => _ProductslovedState();
}

class _ProductslovedState extends State<Productsloved> {
  late final List<ProductModel> _items = List<ProductModel>.from(
    widget.items.isNotEmpty ? widget.items : _demoLovedProducts,
  );

  // ── Données de démo ──────────────────────────────────────────
  // TODO: à retirer une fois branché sur la vraie source (API/provider).
  static final List<ProductModel> _demoLovedProducts = [
    ProductModel(
      id: '1',
      name: 'AirPods Pro 2',
      description: 'Réduction de bruit active, boîtier de charge MagSafe.',
      brand: 'Apple',
      model: 'A2698',
      price: 2100,
      imageUrl: 'https://picsum.photos/seed/airpodspro2/400/400',
      totalSales: 143,
      totalLikes: 389,
      totalWishlists: 92,
      isLiked: true,
      isWishlisted: false,
    ),
    ProductModel(
      id: '2',
      name: 'iPad Air 5',
      description: 'Puce M1, écran 10.9", très bon état général.',
      brand: 'Apple',
      model: 'A2588',
      price: 6100,
      imageUrl: 'https://picsum.photos/seed/ipadair5/400/400',
      totalSales: 76,
      totalLikes: 231,
      totalWishlists: 58,
      isLiked: true,
      isWishlisted: true,
    ),
    ProductModel(
      id: '3',
      name: 'Xbox Series S',
      description: '512Go, avec manette sans fil, boîte d\'origine.',
      brand: 'Microsoft',
      model: 'RRS-00005',
      price: 3400,
      imageUrl: 'https://picsum.photos/seed/xboxseriess/400/400',
      totalSales: 58,
      totalLikes: 176,
      totalWishlists: 41,
      isLiked: true,
      isWishlisted: false,
    ),
    ProductModel(
      id: '4',
      name: 'Apple Watch SE',
      description: '40mm, GPS, bracelet sport neuf inclus.',
      brand: 'Apple',
      model: 'A2723',
      price: 1900,
      imageUrl: 'https://picsum.photos/seed/applewatchse/400/400',
      totalSales: 91,
      totalLikes: 254,
      totalWishlists: 67,
      isLiked: true,
      isWishlisted: true,
    ),
  ];

  void _removeFromLoved(ProductModel product) {
    final removedIndex = _items.indexOf(product);
    if (removedIndex == -1) return;

    setState(() => _items.removeAt(removedIndex));

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('« ${product.name} » retiré de vos produits aimés'),
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: () {
            setState(() {
              final insertIndex = removedIndex.clamp(0, _items.length);
              _items.insert(insertIndex, product);
            });
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: CustomScrollView(
        slivers: [
          ProductsLovedAppbar(itemCount: _items.length),
          if (_items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyLovedProducts(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  // Hauteur fixe (voir note dans Wishlists) plutôt qu'un
                  // aspect ratio, pour éviter tout débordement du contenu
                  // de ProductCard sur écrans étroits.
                  mainAxisExtent: 300,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = _items[index];
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return ProductCard(
                          key: ValueKey(product.id),
                          product: product,
                          width: constraints.maxWidth,
                          onTap: () {
                            // TODO: naviguer vers ProductDetailsPage.
                          },
                          onLikeChanged: (isLiked) {
                            if (!isLiked) _removeFromLoved(product);
                          },
                        );
                      },
                    );
                  },
                  childCount: _items.length,
                ),
              ),
            ),
        ],
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
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Appuyez sur le cœur d\'un article pour le retrouver ici.',
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