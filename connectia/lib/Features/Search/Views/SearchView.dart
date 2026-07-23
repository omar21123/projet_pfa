import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/widgets/Texts/TextSearchBar.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductsHorizontalSection.dart';
import 'package:connectia/Features/Search/widgets/SearchCategoriesRow.dart';
import 'package:connectia/Features/Search/widgets/SearchSiverAppBAr.dart';
import 'package:flutter/material.dart';

class Searchview extends StatefulWidget {
  const Searchview({super.key});

  @override
  State<Searchview> createState() => _SearchviewState();
}

class _SearchviewState extends State<Searchview> {
  String? _selectedCategory;

  final List<String> _categories = const [
    'Tout',
    'Basketball',
    'Chaussures',
    'Training',
    'Yoga',
    'Vélo',
  ];

  // ── Données de démonstration -> remplace par ton repository/API ──
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
  late List<ProductModel> _bestSellers = _mockProducts('bestsellers');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBg(context),
      body: CustomScrollView(
        slivers: [
          Searchsiverappbar(),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Catégories (texte, pas d'image) ────────────────────
          SliverToBoxAdapter(
            child: SearchCategoriesRow(
              categories: _categories,
              selected: _selectedCategory,
              onSelected: (value) => setState(
                () => _selectedCategory = _selectedCategory == value
                    ? null
                    : value,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Recherches récentes ─────────────────────────────────
          SliverToBoxAdapter(
            child: ProductsHorizontalSection(
              title: 'Recherches récentes',
              products: _recentSearches,

              onSeeAllTap: () {},
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Les plus vendus ──────────────────────────────────────
          SliverToBoxAdapter(
            child: ProductsHorizontalSection(
              title: 'Les plus vendus',
              products: _bestSellers,

              onSeeAllTap: () {},
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
          ),
        ],
      ),
    );
  }
}
