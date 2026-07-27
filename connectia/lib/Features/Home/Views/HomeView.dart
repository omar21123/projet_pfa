import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/Navigations/CustomNavigator.dart';
import 'package:connectia/Features/Home/data/Models/CategoryModel.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Home/widgets/CategoryCard.dart';
import 'package:connectia/Features/Home/widgets/HomeHeaderBar.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductsHorizontalSection.dart';
import 'package:connectia/Features/Home/widgets/PromoBannerCard.dart';
import 'package:flutter/material.dart';

class Homeview extends StatefulWidget {
  const Homeview({super.key});

  @override
  State<Homeview> createState() => _HomeviewState();
}

class _HomeviewState extends State<Homeview> {
  String? _selectedCategoryId;

  // ── Données de démonstration -> remplace par ton repository/API ──
  final List<CategoryModel> _categories = const [
    CategoryModel(
      id: 'basket',
      name: 'Basketball',
      imageUrl: 'https://picsum.photos/seed/basket/200',
    ),
    CategoryModel(
      id: 'shoes',
      name: 'Chaussures',
      imageUrl: 'https://picsum.photos/seed/shoes/200',
    ),
    CategoryModel(
      id: 'training',
      name: 'Training',
      imageUrl: 'https://picsum.photos/seed/training/200',
    ),
    CategoryModel(
      id: 'yoga',
      name: 'Yoga',
      imageUrl: 'https://picsum.photos/seed/yoga/200',
    ),
    CategoryModel(
      id: 'bike',
      name: 'Vélo',
      imageUrl: 'https://picsum.photos/seed/bike/200',
    ),
  ];

  List<ProductModel> _mockProducts(String seed) => List.generate(
    6,
    (i) => ProductModel(
      id: '$seed-$i',
      name: 'Article ${i + 1}',
      description: 'Description courte de l\'article, matière et coupe.',
      imageUrl: 'https://picsum.photos/seed/$seed$i/400/300',
      price: 199.0 + (i * 40),
      brand: 'Marque ${i % 3 + 1}',
      model: 'Modèle X${i + 1}',
      totalSales: 120 + i * 37,
      totalLikes: 800 + i * 210,
      totalWishlists: 300 + i * 95,
      isLiked: i % 2 == 0,
      isWishlisted: i % 3 == 0,
    ),
  );

  late List<ProductModel> _recentSearches = _mockProducts('recent');
  late List<ProductModel> _forYou = _mockProducts('foryou');
  late List<ProductModel> _nearYou = _mockProducts('near');
  late List<ProductModel> _topSellers = _mockProducts('sellers');
  late List<ProductModel> _bestProducts = _mockProducts('best');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBg(context),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: HomeHeaderBar(
                userName: 'Mohammed',
                notificationCount: 4,
                onNotificationTap: () async {
                await  CustomNavigator.navigateNotificationsPagePage();
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Catégories ──────────────────────────────────────
            SliverToBoxAdapter(
              child: CategoriesSection(
                categories: _categories,
                selectedCategoryId: _selectedCategoryId,
                onCategoryTap: (id) => setState(() => _selectedCategoryId = id),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Bannière promo ──────────────────────────────────
            SliverToBoxAdapter(
              child: PromoBannerCard(
                title: 'Passe au niveau supérieur',
                subtitle: 'Trouve du matériel top pour ta prochaine session.',
                imageUrl: 'https://picsum.photos/seed/promo/800/600',
                primaryActionLabel: 'Explorer',
                onPrimaryActionTap: () {},
                secondaryActionLabel: 'Sélection éditeur',
                onSecondaryActionTap: () {},
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── Recherches récentes ──────────────────────────────
            SliverToBoxAdapter(
              child: ProductsHorizontalSection(
                title: 'Tes dernières recherches',
                products: _recentSearches,

                onSeeAllTap: () {},
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Basé sur tes préférences ──────────────────────────
            SliverToBoxAdapter(
              child: ProductsHorizontalSection(
                title: 'Pour toi',
                products: _forYou,

                onSeeAllTap: () {},
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Près de chez toi ──────────────────────────────────
            SliverToBoxAdapter(
              child: ProductsHorizontalSection(
                title: 'Près de chez toi',
                products: _nearYou,

                onSeeAllTap: () {},
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Meilleurs vendeurs ─────────────────────────────────
            SliverToBoxAdapter(
              child: ProductsHorizontalSection(
                title: 'Meilleurs vendeurs',
                products: _topSellers,
                onSeeAllTap: () {},
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Meilleurs produits ─────────────────────────────────
            SliverToBoxAdapter(
              child: ProductsHorizontalSection(
                title: 'Meilleurs produits',
                products: _bestProducts,
                onSeeAllTap: () {},
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
