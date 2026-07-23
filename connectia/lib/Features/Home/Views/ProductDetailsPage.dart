import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Home/widgets/Products/PaymentMethodBadges.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductCategoryChips.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductConfigSelector.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductHeroImage.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductStatsCard.dart';
import 'package:flutter/material.dart';

/// Page détail produit, ouverte depuis ProductCard (Hero image partagée).
class ProductDetailsPage extends StatefulWidget {
  final ProductModel product;
  final void Function(Map<String, String> selectedConfigs)? onAddToCart;

  const ProductDetailsPage({
    super.key,
    required this.product,
    this.onAddToCart,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  static const double _imageHeight = 340;
  static const double _panelOverlap = 28;

  late bool _isLiked = widget.product.isLiked;
  late bool _isWishlisted = widget.product.isWishlisted;
  late int _totalLikes = widget.product.totalLikes;
  late int _totalWishlists = widget.product.totalWishlists;

  final Map<String, String> _selectedOptions = {};

  bool get _allConfigsSelected =>
      widget.product.configs.every((c) => _selectedOptions.containsKey(c.name));

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: AppColors.softBg(context),
      body: CustomScrollView(
        slivers: [
          // ── Image héros + "capuchon" arrondi qui chevauche son bas ──
          // (hauteur fixe connue → pas besoin de marge négative)
          SliverToBoxAdapter(
            child: SizedBox(
              height: _imageHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ProductHeroImage(
                    productId: product.id,
                    imageUrl: product.imageUrl,
                    height: _imageHeight,
                    isLiked: _isLiked,
                    isWishlisted: _isWishlisted,
                    onBackTap: () => Navigator.pop(context),
                    onLikeTap: () => setState(() {
                      _isLiked = !_isLiked;
                      _totalLikes += _isLiked ? 1 : -1;
                    }),
                    onWishlistTap: () => setState(() {
                      _isWishlisted = !_isWishlisted;
                      _totalWishlists += _isWishlisted ? 1 : -1;
                    }),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: _imageHeight - _panelOverlap,
                    height: _panelOverlap,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background(context),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Panneau de contenu, juste après le capuchon ────
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.background(context),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Titre / marque / modèle / prix ───────────
                  Text(
                    product.name,
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.brand} · ${product.model}',
                    style: TextStyle(
                      color: AppColors.secondary(context),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${product.price.toStringAsFixed(0)} MAD',
                    style: TextStyle(
                      color: AppColors.primary(context),
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Catégories ─────────────────────────────────
                  ProductCategoryChips(categories: product.categories),
                  if (product.categories.isNotEmpty) const SizedBox(height: 20),

                  // ── Statistiques ───────────────────────────────
                  ProductStatsCard(
                    totalOrders: product.totalSales,
                    totalLikes: _totalLikes,
                    totalWishlists: _totalWishlists,
                  ),
                  const SizedBox(height: 24),

                  // ── Configurations (taille, couleur...) ─────────
                  ProductConfigSelector(
                    configs: product.configs,
                    selectedOptions: _selectedOptions,
                    onOptionSelected: (configName, option) {
                      setState(() => _selectedOptions[configName] = option);
                    },
                  ),

                  // ── Moyens de paiement acceptés ─────────────────
                  Text(
                    'Paiement',
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  PaymentMethodBadges(methods: product.allowedPayments),
                  const SizedBox(height: 24),

                  // ── Description ──────────────────────────────────
                  Text(
                    'Description',
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: TextStyle(
                      color: AppColors.secondary(context),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bouton d'achat, épinglé en bas ───────────────────────
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (product.configs.isNotEmpty && !_allConfigsSelected)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Choisis une option pour chaque configuration.',
                  style: TextStyle(
                    color: AppColors.wishlist(context),
                    fontSize: 12,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _allConfigsSelected
                    ? () => widget.onAddToCart?.call(_selectedOptions)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary(context),
                  foregroundColor: AppColors.onPrimary(context),
                  disabledBackgroundColor: AppColors.secondary(
                    context,
                  ).withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Ajouter au panier',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
