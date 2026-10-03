import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/widgets/Buttons/CircleIconButton.dart';
import 'package:connectia/Features/Account/data/FavoritesCubit.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Wishlist/widgets/ChooseWishlistDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onFavoriteToggle;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.width = 190,
    this.onLikeChanged,
    this.onWishlistChanged,
    this.onDelete,
    this.onFavoriteToggle,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
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
    final promo = widget.product.promotionLabel;

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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + boutons like/wishlist + promo badge ──
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Image.network(
                      widget.product.resolvedImageUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 80,
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
                // ── Promotion badge ────────────────────────
                if (promo != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.wishlist(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        promo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
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
                          context.read<FavoritesCubit>().toggleFavorite(
                                int.tryParse(widget.product.id) ?? 0,
                              );
                          widget.onLikeChanged?.call(_isLiked);
                          widget.onFavoriteToggle?.call(_isLiked);
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
                          final productId = int.tryParse(widget.product.id);
                          if (productId == null) return;

                          showChooseWishlistDialog(
                            context,
                            productId: productId,
                            onSelected: (wishListId, name) {
                              setState(() {
                                _isWishedList = true;
                                _totalWishlists = _totalWishlists + 1;
                              });
                              widget.onWishlistChanged?.call(_isWishedList);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (widget.onDelete != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: CircleIconButton(
                      icon: Icons.delete_outline,
                      color: AppColors.wishlist(context),
                      onTap: widget.onDelete!,
                    ),
                  ),
              ],
            ),

            // ── Infos ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.product.model.isNotEmpty
                        ? '${widget.product.brand} · ${widget.product.model}'
                        : widget.product.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.secondary(context),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${widget.product.effectivePrice.toStringAsFixed(0)} MAD',
                        style: TextStyle(
                          color: AppColors.primary(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (widget.product.hasPromotion) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${widget.product.price.toStringAsFixed(0)} MAD',
                          style: TextStyle(
                            color: AppColors.secondary(context),
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                            decorationColor:
                                AppColors.secondary(context).withValues(alpha: 0.5),
                          ),
                        ),
                      ],
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
