import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/widgets/Buttons/CircleIconButton.dart';
import 'package:connectia/Core/widgets/Buttons/StatChip.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:flutter/material.dart';

/// Page détail produit, ouverte depuis ProductCard via Navigator.push.
/// L'image partage le tag Hero 'product-image-{id}' avec ProductCard
/// pour l'animation de transition.
class ProductDetailsPage extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onAddToCart;

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

  late bool _isLiked = widget.product.isLiked;
  late bool _isWishlisted = widget.product.isWishlisted;
  late int _totalLikes = widget.product.totalLikes;
  late int _totalWishlists = widget.product.totalWishlists;

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: AppColors.softBg(context),
      body: Stack(
        children: [
          // ── Image héro plein largeur ─────────────────────────
          Hero(
            tag: 'product-image-${product.id}',
            child: Image.network(
              product.imageUrl,
              height: _imageHeight,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: _imageHeight,
                color: AppColors.accent20(context),
                alignment: Alignment.center,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.secondary(context),
                  size: 48,
                ),
              ),
            ),
          ),

          // ── Bouton retour ─────────────────────────────────────
          Positioned(
            top: 12,
            left: 12,
            child: SafeArea(
              child: CircleIconButton(
                icon: Icons.arrow_back,
                color: AppColors.primaryText(context),
                onTap: () => Navigator.pop(context),
              ),
            ),
          ),

          // ── Like / Wishlist ────────────────────────────────────
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: Row(
                children: [
                  CircleIconButton(
                    icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? AppColors.wishlist(context) : AppColors.primaryText(context),
                    onTap: () {
                      setState(() {
                        _isLiked = !_isLiked;
                        _totalLikes += _isLiked ? 1 : -1;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  CircleIconButton(
                    icon: _isWishlisted ? Icons.bookmark : Icons.bookmark_border,
                    color: _isWishlisted ? AppColors.primary(context) : AppColors.primaryText(context),
                    onTap: () {
                      setState(() {
                        _isWishlisted = !_isWishlisted;
                        _totalWishlists += _isWishlisted ? 1 : -1;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Panneau de contenu, chevauche le bas de l'image ────
          Positioned.fill(
            top: _imageHeight - 28,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          StatChip(
                            icon: Icons.shopping_bag_outlined,
                            value: _formatCount(product.totalSales),
                          ),
                          StatChip(
                            icon: Icons.favorite_border,
                            value: _formatCount(_totalLikes),
                          ),
                          StatChip(
                            icon: Icons.bookmark_border,
                            value: _formatCount(_totalWishlists),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
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
          ),
        ],
      ),

      // ── Bouton d'achat, épinglé en bas ───────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onAddToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(context),
                foregroundColor: AppColors.onPrimary(context),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text(
                'Ajouter au panier',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ),
      ),
    );
  }
}