import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductHeroImage.dart';
import 'package:flutter/material.dart';

class Productdetailsappbar extends StatefulWidget {
  const Productdetailsappbar({
    super.key,
    required this.product,
    required this.onLikeTap,
    required this.onBackTap,
    required this.onWishlistTap,
  });
  static const double _imageHeight = 340;
  final ProductModel product;
  final void Function (int value) onLikeTap;
  final VoidCallback onBackTap;
  final void Function (int value) onWishlistTap;
  @override
  State<Productdetailsappbar> createState() => _ProductdetailsappbarState();
}

class _ProductdetailsappbarState extends State<Productdetailsappbar> {
  late bool _isLiked = widget.product.isLiked;
  late bool _isWishlisted = widget.product.isWishlisted;
  @override
  Widget build(BuildContext context) {
    return // ── Image héros dans une SliverAppBar ──
    SliverAppBar(
      pinned: false,
      floating: false,
      automaticallyImplyLeading: false,
      expandedHeight: Productdetailsappbar._imageHeight,
      backgroundColor: AppColors.background(context),
      flexibleSpace: FlexibleSpaceBar(
        background: ProductHeroImage(
          productId: widget.product.id,
          imageUrl: widget.product.imageUrl,
          height: Productdetailsappbar._imageHeight,
          isLiked: _isLiked,
          isWishlisted: _isWishlisted,
          onBackTap: widget.onBackTap,
          onLikeTap: () => setState(() {
            _isLiked = !_isLiked;
            widget.onLikeTap.call(_isLiked?1:-1);
          }),
          onWishlistTap: () => setState(() {
            _isWishlisted = !_isWishlisted;
            widget.onWishlistTap.call(_isWishlisted ? 1:-1);
          }),
        ),
      ),
    );
  }
}
