import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

/// Barre de recherche "factice" : non éditable, cliquable uniquement.
/// Au tap -> navigation vers la page de suggestions de recherche.
/// Le placeholder anime en boucle (effet machine à écrire) à travers
/// une liste de suggestions ("Rechercher des produits", "... des marques", etc.)
class SearchEntryButton extends StatelessWidget {
  final VoidCallback onTap;
  final List<String> suggestions;

  const SearchEntryButton({
    super.key,
    required this.onTap,
    this.suggestions = const [
      'Rechercher des produits',
      'Rechercher des marques',
      'Rechercher des catégories',
      'Recherchez selon vos envies',
    ],
  });

  @override
  Widget build(BuildContext context) {
    final secondaryColor = AppColors.secondary(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: secondaryColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 22, color: secondaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedTextKit(
                  animatedTexts: suggestions
                      .map(
                        (text) => TypewriterAnimatedText(
                          text,
                          textStyle: TextStyle(
                            fontSize: 15,
                            color: secondaryColor,
                          ),
                          speed: const Duration(milliseconds: 55),
                          curve: Curves.linear,
                        ),
                      )
                      .toList(),
                  isRepeatingAnimation: true,
                  repeatForever: true,
                  pause: const Duration(milliseconds: 1400),
                  displayFullTextOnTap: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
