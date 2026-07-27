import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Account/Widgets/Wishlist/WishlistAppbar.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductCard.dart';
import 'package:flutter/material.dart';

/// Page "Liste de souhaits".
///
/// TODO: `items` est injecté depuis l'extérieur pour l'instant — brancher
/// sur le vrai service/provider de wishlist (ex: WishlistService.fetch())
/// une fois l'API dispo, et remplacer par un chargement asynchrone si besoin.
/// En attendant, `_demoWishlist` sert de données de démo si rien n'est
/// injecté — à supprimer une fois la vraie source branchée.
class Wishlists extends StatefulWidget {
  final List<ProductModel> items;

  const Wishlists({super.key, this.items = const []});

  @override
  State<Wishlists> createState() => _WishlistsState();
}

class _WishlistsState extends State<Wishlists> {
  late final List<ProductModel> _items = List<ProductModel>.from(
    widget.items.isNotEmpty ? widget.items : _demoWishlist,
  );

  // ── Données de démo ──────────────────────────────────────────
  // TODO: à retirer une fois branché sur la vraie source (API/provider).
  static final List<ProductModel> _demoWishlist = [
    ProductModel(
      id: '1',
      name: 'iPhone 13 Pro',
      description: 'Excellent état, batterie 91%, avec boîte et accessoires.',
      brand: 'Apple',
      model: 'A2638',
      price: 8500,
      imageUrl: 'https://picsum.photos/seed/iphone13pro/400/400',
      totalSales: 128,
      totalLikes: 342,
      totalWishlists: 76,
      isLiked: false,
      isWishlisted: true,
    ),
    ProductModel(
      id: '2',
      name: 'MacBook Air M1',
      description: '8Go RAM / 256Go SSD, quelques micro-rayures sur le capot.',
      brand: 'Apple',
      model: 'M1 2020',
      price: 9200,
      imageUrl: 'https://picsum.photos/seed/macbookairm1/400/400',
      totalSales: 54,
      totalLikes: 210,
      totalWishlists: 63,
      isLiked: true,
      isWishlisted: true,
    ),
    ProductModel(
      id: '3',
      name: 'PlayStation 5',
      description: 'Édition standard avec 2 manettes et 3 jeux inclus.',
      brand: 'Sony',
      model: 'CFI-1216A',
      price: 6800,
      imageUrl: 'https://picsum.photos/seed/ps5console/400/400',
      totalSales: 97,
      totalLikes: 415,
      totalWishlists: 121,
      isLiked: false,
      isWishlisted: true,
    ),
    ProductModel(
      id: '4',
      name: 'Samsung Galaxy S22',
      description: 'Double SIM, débloqué tout opérateur, écran impeccable.',
      brand: 'Samsung',
      model: 'SM-S901B',
      price: 4300,
      imageUrl: 'https://picsum.photos/seed/galaxys22/400/400',
      totalSales: 61,
      totalLikes: 158,
      totalWishlists: 39,
      isLiked: false,
      isWishlisted: true,
    ),
    ProductModel(
      id: '5',
      name: 'Sony WH-1000XM4',
      description: 'Casque à réduction de bruit, très peu utilisé.',
      brand: 'Sony',
      model: 'WH-1000XM4',
      price: 1650,
      imageUrl: 'https://picsum.photos/seed/sonywh1000xm4/400/400',
      totalSales: 82,
      totalLikes: 190,
      totalWishlists: 47,
      isLiked: true,
      isWishlisted: true,
    ),
    ProductModel(
      id: '6',
      name: 'Nintendo Switch OLED',
      description: 'Modèle OLED blanc, avec dock et 2 jeux physiques.',
      brand: 'Nintendo',
      model: 'HEG-001',
      price: 3200,
      imageUrl: 'https://picsum.photos/seed/switcholed/400/400',
      totalSales: 73,
      totalLikes: 264,
      totalWishlists: 88,
      isLiked: false,
      isWishlisted: true,
    ),
  ];

  void _removeFromWishlist(ProductModel product) {
    final removedIndex = _items.indexOf(product);
    if (removedIndex == -1) return;

    setState(() => _items.removeAt(removedIndex));

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('« ${product.name} » retiré de vos favoris'),
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
          WishlistAppbar(itemCount: _items.length),
          if (_items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyWishlist(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  // Hauteur fixe plutôt qu'un ratio lié à la largeur : le
                  // contenu de ProductCard (image + texte) a une hauteur
                  // quasi constante, donc un aspect ratio le fait déborder
                  // sur les écrans étroits. Ajuster cette valeur si le texte
                  // wrap différemment (police système plus grande, etc.).
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
                          onWishlistChanged: (isWishlisted) {
                            if (!isWishlisted) _removeFromWishlist(product);
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

class _EmptyWishlist extends StatelessWidget {
  const _EmptyWishlist();

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
              'Votre liste de souhaits est vide',
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