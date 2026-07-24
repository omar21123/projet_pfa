import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Home/data/Models/ProductConfigsOptions.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Home/widgets/Products/BrandVerifiedBadge.dart';
import 'package:connectia/Features/Home/widgets/Products/PaymentMethodBadges.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductCategoryChips.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductConfigSelector.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductConfigsSliverList.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductDetailsAppBar.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductDetailsStats.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductHeroImage.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductStatsCard.dart';
import 'package:connectia/Features/Search/widgets/SearchCategoriesRow.dart';
import 'package:connectia/Features/Search/widgets/SearchCategoryChip.dart';
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
  final List<String> _categories = const [
    'Tout',
    'Basketball',
    'Chaussures',
    'Training',
    'Yoga',
    'Vélo',
  ];

  List<ProductConfigsOptions> productConfigsOptionsList = [
    ProductConfigsOptions(
      id: 1,
      name: 'Color',
      options: [
        OptionModel(id: 101, name: 'Red'),
        OptionModel(id: 102, name: 'Blue'),
        OptionModel(id: 103, name: 'Green'),
      ],
    ),
    ProductConfigsOptions(
      id: 2,
      name: 'Size',
      options: [
        OptionModel(id: 201, name: 'Small'),
        OptionModel(id: 202, name: 'Medium'),
        OptionModel(id: 203, name: 'Large'),
        OptionModel(id: 204, name: 'Extra Large'),
      ],
    ),
    ProductConfigsOptions(
      id: 3,
      name: 'Material',
      options: [
        OptionModel(id: 301, name: 'Cotton'),
        OptionModel(id: 302, name: 'Polyester'),
        OptionModel(id: 303, name: 'Wool'),
      ],
    ),
    ProductConfigsOptions(
      id: 4,
      name: 'Storage',
      options: [
        OptionModel(id: 401, name: '64GB'),
        OptionModel(id: 402, name: '128GB'),
        OptionModel(id: 403, name: '256GB'),
        OptionModel(id: 404, name: '512GB'),
      ],
    ),
    ProductConfigsOptions(
      id: 5,
      name: 'Warranty',
      options: [
        OptionModel(id: 501, name: '1 Year'),
        OptionModel(id: 502, name: '2 Years'),
        OptionModel(id: 503, name: 'No Warranty'),
      ],
    ),
  ];

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
            child: SizedBox(
              height: 40, // adjust to your chip height
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length - 1,
                itemBuilder: (context, index) {
                  return SearchCategoryChip(
                    isSelected: false,
                    label: _categories[index],
                    onTap: () {},
                  );
                },
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: BrandVerifiedBadge(
              iconPath:
                  'https://nmp.about.nike.com/about/prod/cf68f541-fc92-4373-91cb-086ae0fe2f88/001-nike-logos-swoosh-black.jpg?m=eyJlZGl0cyI6eyJqcGVnIjp7InF1YWxpdHkiOjEwMH0sIndlYnAiOnsicXVhbGl0eSI6MTAwfSwiZXh0cmFjdCI6eyJsZWZ0IjowLCJ0b3AiOjAsIndpZHRoIjo1MDAwLCJoZWlnaHQiOjI4MTN9LCJyZXNpemUiOnsid2lkdGgiOjE5MjB9fX0%3D&s=61f6e4257083078e443fcbec16a22a762b57a3182ddbeba67f9f92799b2dec94',
              label: 'Nike',
              isVerified: true,
              onTap: () {}, // null -> non-cliquable, pas d'effet de scale
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Lumix G-Pro X1',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText(
                    context,
                  ), // noir / blanc selon le mode
                  height: 1.2,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                '1,499.00 MAD',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary(context), // teal brand color
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: ProductDetailsStats(
                rating: '4.9',
                sales: '2.4k+',
                favorites: '842',
              ),
            ),
          ),
          ProductConfigsSliverList(
            configs: productConfigsOptionsList, // List<ProductConfigsOptions>
            onChanged: (selections) {
              
            },
          ),
        ],
      ),
    );
  }
}
