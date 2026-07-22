import 'dart:async';
import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/Navigations/CustomNavigator.dart';
import 'package:connectia/Core/widgets/Texts/TextSearchBar.dart';
import 'package:connectia/Features/Search/widgets/SuggestionCard.dart';
import 'package:flutter/material.dart';

class Searchtypingsuggestions extends StatefulWidget {
  const Searchtypingsuggestions({super.key});

  @override
  State<Searchtypingsuggestions> createState() =>
      _SearchtypingsuggestionsState();
}

class _SearchtypingsuggestionsState extends State<Searchtypingsuggestions> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  // Demo data only — à remplacer plus tard par un vrai historique /
  // appel API (produits, marques, catégories...).
  final List<String> _allSuggestions = const [
    'Robe d\'été fleurie',
    'Baskets Nike Air Max',
    'Sac à main cuir',
    'T-shirt Zara homme',
    'Montre connectée',
    'Parfum Chanel',
    'Chaussures de sport',
    'Veste en jean',
  ];

  // Ce qui est affiché à l'écran : historique complet si champ vide,
  // résultats filtrés sinon.
  List<String> _displayedResults = const [];

  @override
  void initState() {
    super.initState();
    _displayedResults = _allSuggestions;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    setState(() {}); // pour rafraîchir le bouton clear immédiatement

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    if (!mounted) return;

    setState(() {
      if (query.trim().isEmpty) {
        _displayedResults = _allSuggestions;
      } else {
        _displayedResults = _allSuggestions
            .where((s) => s.toLowerCase().contains(query.toLowerCase()))
            .toList();
        // TODO: remplacer ce filtre local par un vrai appel API
        // (produits/marques/catégories) une fois le backend branché.
      }
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
          autofocus: true,
          onChanged: _onQueryChanged,
          onClear: () {
            _controller.clear();
            _onQueryChanged('');
          },
        ),
      ),
      body: _displayedResults.isEmpty
          ? Center(
              child: Text(
                'Aucun résultat trouvé',
                style: TextStyle(color: AppColors.secondary(context)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _displayedResults.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: AppColors.secondary(context).withValues(alpha: 0.15),
              ),
              itemBuilder: (context, index) {
                final suggestion = _displayedResults[index];
                return SuggestionCard(
                  isHistory: _controller.text.isEmpty,
                  text: suggestion,
                  onTap: () {
                    _controller.text = suggestion;
                    _performSearch(suggestion);
                    CustomNavigator.navigateSearchResultsPage(suggestion);
                  },
                );
              },
            ),
    );
  }
}
