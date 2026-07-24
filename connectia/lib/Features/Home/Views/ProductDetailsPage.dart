import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Home/widgets/Products/PaymentMethodBadges.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductCategoryChips.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductConfigSelector.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductDetailsAppBar.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductHeroImage.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductStatsCard.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
  late int _totalLikes = widget.product.totalLikes;
  late int _totalWishlists = widget.product.totalWishlists;
  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: AppColors.softBg(context),
      body: CustomScrollView(
        slivers: [
          Productdetailsappbar(
            product: widget.product,
            onBackTap: () => context.pop(),
            onLikeTap: (value) {
              _totalLikes = _totalLikes + value;
            },
            onWishlistTap: (value) {
              _totalWishlists = _totalWishlists + value;
            },
          ),
          SliverToBoxAdapter(
            child: Text(
              widget.product.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.primary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
