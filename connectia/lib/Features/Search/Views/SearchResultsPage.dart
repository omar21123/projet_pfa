import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/widgets/Texts/TextSearchBar.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Home/widgets/ProductCard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class SearchResultsPage extends StatefulWidget {
  final String initialQuery;

  const SearchResultsPage({super.key, required this.initialQuery});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;
  List<ProductModel> _results = [];

  // Demo data only — à remplacer par un vrai appel API/repository.
  static final List<ProductModel> _demoProducts = [
    ProductModel(
      id: '1',
      name: 'Robe d\'été fleurie',
      description: 'Robe légère à motifs floraux, idéale pour l\'été.',
      brand: 'Zara',
      model: 'Summer Collection',
      price: 249,
      imageUrl: 'https://picsum.photos/seed/dress/400/400',
      isLiked: false,
      isWishlisted: false,
      totalLikes: 120,
      totalWishlists: 34,
      totalSales: 58,
    ),
    ProductModel(
      id: '2',
      name: 'Baskets Nike Air Max',
      description: 'Baskets confortables pour un usage quotidien.',
      brand: 'Nike',
      model: 'Air Max 270',
      price: 899,
      imageUrl: 'https://picsum.photos/seed/nike/400/400',
      isLiked: true,
      isWishlisted: false,
      totalLikes: 980,
      totalWishlists: 210,
      totalSales: 430,
    ),
    ProductModel(
      id: '3',
      name: 'Sac à main cuir',
      description:
          'Sac en cuir véritable, plusieurs compartiments et finitions soignées.',
      brand: 'Zara',
      model: 'Classic Tote',
      price: 599,
      imageUrl: 'https://picsum.photos/seed/bag/400/400',
      isLiked: false,
      isWishlisted: true,
      totalLikes: 340,
      totalWishlists: 88,
      totalSales: 120,
    ),
    ProductModel(
      id: '4',
      name: 'Montre connectée',
      description: 'Suivi santé, notifications, autonomie 7 jours.',
      brand: 'Samsung',
      model: 'Galaxy Watch 6',
      price: 1499,
      imageUrl: 'https://picsum.photos/seed/watch/400/400',
      isLiked: false,
      isWishlisted: false,
      totalLikes: 512,
      totalWishlists: 143,
      totalSales: 76,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _runSearch(widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    setState(() => _isLoading = true);

    // TODO: remplacer par un vrai appel repository/API.
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    setState(() {
      _results = query.trim().isEmpty
          ? _demoProducts
          : _demoProducts
                .where(
                  (p) =>
                      p.name.toLowerCase().contains(query.toLowerCase()) ||
                      p.brand.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryText(context)),
        titleSpacing: 0,
        title: Textsearchbar(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: (value) => setState(() {}), // pour le bouton clear
          onClear: () {
            _controller.clear();
            _runSearch('');
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _isLoading
                    ? 'Recherche en cours...'
                    : '${_results.length} résultat(s) pour "${_controller.text}"',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.secondary(context),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                ? Center(
                    child: Text(
                      'Aucun résultat trouvé',
                      style: TextStyle(color: AppColors.secondary(context)),
                    ),
                  )
                : MasonryGridView.count(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final product = _results[index];
                      return ProductCard(
                        product: product,
                        width: double.infinity,
                        onTap: () {
                          // TODO: naviguer vers la page détail produit
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
