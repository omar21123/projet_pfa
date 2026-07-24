import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/widgets/Buttons/CircleIconButton.dart';
import 'package:flutter/material.dart';

/// Image héro plein largeur + bouton retour + boutons like/wishlist,
/// positionnés en overlay sur l'image.
class ProductHeroImage extends StatelessWidget {
  final String productId;
  final String imageUrl;
  final double height;
  final bool isLiked;
  final bool isWishlisted;
  final VoidCallback onBackTap;
  final VoidCallback onLikeTap;
  final VoidCallback onWishlistTap;

  const ProductHeroImage({
    super.key,
    required this.productId,
    required this.imageUrl,
    required this.isLiked,
    required this.isWishlisted,
    required this.onBackTap,
    required this.onLikeTap,
    required this.onWishlistTap,
    this.height = 340,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Hero(
          tag: 'product-image-$productId',
          child: Image.network(
            
            imageUrl,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: height,
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
        Positioned(
          top: 25,
          left: 12,
          child: SafeArea(
            child: CircleIconButton(
              icon: Icons.cancel_outlined,
              color: AppColors.primaryText(context),
              onTap: onBackTap,
            ),
          ),
        ),
        Positioned(
          top: 25,
          right: 12,
          child: SafeArea(
            child: Row(
              children: [
                CircleIconButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked
                      ? AppColors.wishlist(context)
                      : AppColors.primaryText(context),
                  onTap: onLikeTap,
                ),
                const SizedBox(width: 8),
                CircleIconButton(
                  icon: isWishlisted ? Icons.bookmark : Icons.bookmark_border,
                  color: isWishlisted
                      ? AppColors.primary(context)
                      : AppColors.primaryText(context),
                  onTap: onWishlistTap,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
