import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/widgets/Buttons/CircleIconButton.dart';
import 'package:connectia/Core/widgets/Buttons/StatChip.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:flutter/material.dart';

/// Carte produit pour le feed Home (carrousels horizontaux) — et réutilisable
/// dans une grille (ex: Liste de souhaits) en passant `width` dynamiquement.
class ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final double width;
  // Optionnels : permettent au parent de réagir aux changements
  // (ex: retirer la carte de la liste quand elle est dé-likée/wishlistée).
  final ValueChanged<bool>? onLikeChanged;
  final ValueChanged<bool>? onWishlistChanged;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.width = 190,
    this.onLikeChanged,
    this.onWishlistChanged,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  bool _isLiked = false;
  bool _isWishedList = false;
  int _totalLikes = 0;
  int _totalWishlists = 0;
  @override
  void initState() {
    super.initState();
    _isLiked = widget.product.isLiked;
    _isWishedList = widget.product.isWishlisted;
    _totalLikes = widget.product.totalLikes;
    _totalWishlists = widget.product.totalWishlists;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.secondary(context).withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + boutons like/wishlist ──────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  // Tag partagé avec ProductDetailsPage pour l'animation Hero.
                  child: Hero(
                    tag: 'product-image-${widget.product.id}',
                    child: Image.network(
                      widget.product.imageUrl,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 130,
                        color: AppColors.accent20(context),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.secondary(context),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      CircleIconButton(
                        icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked
                            ? AppColors.wishlist(context)
                            : AppColors.primaryText(context),
                        onTap: () {
                          setState(() {
                            _isLiked = !_isLiked;
                            _totalLikes = _isLiked
                                ? _totalLikes + 1
                                : _totalLikes - 1;
                          });
                          widget.onLikeChanged?.call(_isLiked);
                        },
                      ),
                      const SizedBox(width: 6),
                      CircleIconButton(
                        icon: _isWishedList
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: _isWishedList
                            ? AppColors.primary(context)
                            : AppColors.primaryText(context),
                        onTap: () {
                          setState(() {
                            _isWishedList = !_isWishedList;
                            _totalWishlists = _isWishedList
                                ? _totalWishlists + 1
                                : _totalWishlists - 1;
                          });
                          widget.onWishlistChanged?.call(_isWishedList);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Infos ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.secondary(context),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.product.brand} · ${widget.product.model}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.secondary(context),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.product.price.toStringAsFixed(0)} MAD',
                    style: TextStyle(
                      color: AppColors.primary(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Divider(
                    height: 1,
                    color: AppColors.secondary(context).withValues(alpha: 0.15),
                  ),
                  const SizedBox(height: 8),
                  // ── Stats : ventes / likes / wishlists ─────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatChip(
                        icon: Icons.shopping_bag_outlined,
                        value: _formatCount(widget.product.totalSales),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}