import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/Navigations/CustomNavigator.dart';
import 'package:connectia/Core/shared/Models/BrandModel.dart';
import 'package:connectia/Features/Home/data/Models/ProductConfigsOptions.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Home/widgets/Products/AddToCartButton.dart';
import 'package:connectia/Features/Home/widgets/Products/BrandVerifiedBadge.dart';
import 'package:connectia/Features/Home/widgets/Products/PaymentMethodSelector.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductConfigsSliverList.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductDescription.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductDetailsAppBar.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductDetailsStats.dart';
import 'package:connectia/Features/Home/widgets/Products/QuantitySelector.dart';
import 'package:connectia/Features/Search/widgets/SearchCategoryChip.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Marges horizontales et rythme vertical partagés par toute la page.
const double _kHPad = 20;
const double _kSectionGap = 28;

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

  PaymentMethod _selectedPayment = PaymentMethod.cod;
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
            onLikeTap: (value) => setState(() => _totalLikes += value),
            onWishlistTap: (value) => setState(() => _totalWishlists += value),
          ),

          // ── Catégories ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: _kHPad),
                  itemCount: _categories.length - 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
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
          ),

          // ── Marque ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_kHPad, 20, _kHPad, 0),
              child: BrandVerifiedBadge(
                iconPath:
                    'https://nmp.about.nike.com/about/prod/cf68f541-fc92-4373-91cb-086ae0fe2f88/001-nike-logos-swoosh-black.jpg?m=eyJlZGl0cyI6eyJqcGVnIjp7InF1YWxpdHkiOjEwMH0sIndlYnAiOnsicXVhbGl0eSI6MTAwfSwiZXh0cmFjdCI6eyJsZWZ0IjowLCJ0b3AiOjAsIndpZHRoIjo1MDAwLCJoZWlnaHQiOjI4MTN9LCJyZXNpemUiOnsid2lkdGgiOjE5MjB9fX0%3D&s=61f6e4257083078e443fcbec16a22a762b57a3182ddbeba67f9f92799b2dec94',
                label: 'Nike',
                isVerified: true,
                onTap: () async {
                  await CustomNavigator.navigateBrandInfoPage(
                    BrandModel(
                      countryName: 'Morocco',
                      description:
                          'Le Lumix G-Pro X1 est un appareil photo hybride conçu pour '
                          'les photographes exigeants qui recherchent à la fois performance et '
                          'portabilité. Doté d\'un capteur de nouvelle génération et d\'un '
                          'processeur d\'image ultra-rapide, il offre une qualité d\'image '
                          'exceptionnelle même dans des conditions de faible luminosité. '
                          'Son autofocus hybride à détection de phase garantit une mise au '
                          'point rapide et précise, idéale pour la photographie de sport, '
                          'de portrait ou de voyage.\n\n'
                          'Le boîtier, fabriqué en alliage de magnésium, allie robustesse et '
                          'légèreté, avec une résistance renforcée à la poussière et aux '
                          'projections d\'eau pour une utilisation en extérieur en toute '
                          'sérénité. L\'écran tactile orientable et le viseur électronique '
                          'haute résolution permettent de composer vos images sous tous les '
                          'angles, tandis que la stabilisation d\'image sur 5 axes réduit '
                          'considérablement les flous de bougé, que ce soit en photo ou en '
                          'vidéo 4K.\n\n'
                          'Livré avec l\'objectif standard 18-55mm, ce kit constitue un point '
                          'de départ idéal pour découvrir la photographie créative, tout en '
                          'restant évolutif grâce à la compatibilité avec l\'ensemble de la '
                          'gamme d\'objectifs interchangeables. Que vous soyez débutant '
                          'passionné ou photographe amateur confirmé, le Lumix G-Pro X1 '
                          'saura s\'adapter à votre pratique et vous accompagner dans '
                          'chacun de vos projets créatifs.',
                      isVerified: true,
                      logoUrl:
                          'https://nmp.about.nike.com/about/prod/cf68f541-fc92-4373-91cb-086ae0fe2f88/001-nike-logos-swoosh-black.jpg?m=eyJlZGl0cyI6eyJqcGVnIjp7InF1YWxpdHkiOjEwMH0sIndlYnAiOnsicXVhbGl0eSI6MTAwfSwiZXh0cmFjdCI6eyJsZWZ0IjowLCJ0b3AiOjAsIndpZHRoIjo1MDAwLCJoZWlnaHQiOjI4MTN9LCJyZXNpemUiOnsid2lkdGgiOjE5MjB9fX0%3D&s=61f6e4257083078e443fcbec16a22a762b57a3182ddbeba67f9f92799b2dec94',
                      name: 'NIKE',
                      website: 'https://www.nike.com/ma/en/',
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_kHPad, 5, _kHPad, 0),
              child: BrandVerifiedBadge(
                label: 'TN-19000',
                isVerified: false,
                onTap: () {},
              ),
            ),
          ),
          // ── Titre + prix ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_kHPad, 14, _kHPad, 0),
              child: Text(
                'Lumix G-Pro X1',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText(context),
                  height: 1.2,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_kHPad, 4, _kHPad, 0),
              child: Text(
                '1,499.00 MAD',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary(context),
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
            ),
          ),

          // ── Stats ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                _kHPad,
                _kSectionGap,
                _kHPad,
                0,
              ),
              child: const ProductDetailsStats(
                rating: '4.9',
                sales: '2.4k+',
                favorites: '842',
              ),
            ),
          ),

          // ── Configs (a déjà son padding interne) ──────────────
          SliverPadding(
            padding: const EdgeInsets.only(top: _kSectionGap),
            sliver: ProductConfigsSliverList(
              configs: productConfigsOptionsList,
              padding: const EdgeInsets.symmetric(horizontal: _kHPad),
              onChanged: (selections) {},
            ),
          ),

          // ── Quantité ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                _kHPad,
                _kSectionGap,
                _kHPad,
                0,
              ),
              child: QuantitySelector(
                initialValue: 1,
                max: 10,
                onChanged: (qty) {},
              ),
            ),
          ),

          // ── Paiement ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                _kHPad,
                _kSectionGap,
                _kHPad,
                0,
              ),
              child: PaymentMethodSelector(
                onChanged: (method) =>
                    setState(() => _selectedPayment = method),
              ),
            ),
          ),

          // ── Description ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                _kHPad,
                _kSectionGap,
                _kHPad,
                0,
              ),
              child: ProductDescription(
                description:
                    'Le Lumix G-Pro X1 est un appareil photo hybride conçu pour '
                    'les photographes exigeants qui recherchent à la fois performance et '
                    'portabilité. Doté d\'un capteur de nouvelle génération et d\'un '
                    'processeur d\'image ultra-rapide, il offre une qualité d\'image '
                    'exceptionnelle même dans des conditions de faible luminosité. '
                    'Son autofocus hybride à détection de phase garantit une mise au '
                    'point rapide et précise, idéale pour la photographie de sport, '
                    'de portrait ou de voyage.\n\n'
                    'Le boîtier, fabriqué en alliage de magnésium, allie robustesse et '
                    'légèreté, avec une résistance renforcée à la poussière et aux '
                    'projections d\'eau pour une utilisation en extérieur en toute '
                    'sérénité. L\'écran tactile orientable et le viseur électronique '
                    'haute résolution permettent de composer vos images sous tous les '
                    'angles, tandis que la stabilisation d\'image sur 5 axes réduit '
                    'considérablement les flous de bougé, que ce soit en photo ou en '
                    'vidéo 4K.\n\n'
                    'Livré avec l\'objectif standard 18-55mm, ce kit constitue un point '
                    'de départ idéal pour découvrir la photographie créative, tout en '
                    'restant évolutif grâce à la compatibilité avec l\'ensemble de la '
                    'gamme d\'objectifs interchangeables. Que vous soyez débutant '
                    'passionné ou photographe amateur confirmé, le Lumix G-Pro X1 '
                    'saura s\'adapter à votre pratique et vous accompagner dans '
                    'chacun de vos projets créatifs.',
              ),
            ),
          ),

          // ── Espace pour ne pas être caché par le bouton fixe ──
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(_kHPad, 12, _kHPad, 12),
          decoration: BoxDecoration(
            color: AppColors.background(context),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            height: 56,
            child: AddToCartButton(
              onTap: () {
                // logique ajout au panier
              },
            ),
          ),
        ),
      ),
    );
  }
}
