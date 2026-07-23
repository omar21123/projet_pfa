import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Home/data/Models/ProductConfig.dart';
import 'package:flutter/material.dart';

/// Sélecteur de configurations produit (ex: Taille, Couleur...).
/// L'utilisateur doit choisir une option par config avant d'ajouter au panier.
class ProductConfigSelector extends StatelessWidget {
  final List<ProductConfig> configs;
  final Map<String, String> selectedOptions;
  final void Function(String configName, String option) onOptionSelected;

  const ProductConfigSelector({
    super.key,
    required this.configs,
    required this.selectedOptions,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (configs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: configs
          .map(
            (config) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.name,
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: config.options.map((option) {
                      final isSelected = selectedOptions[config.name] == option;
                      return GestureDetector(
                        onTap: () => onOptionSelected(config.name, option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary(context)
                                : AppColors.surface(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary(context)
                                  : AppColors.secondary(context).withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            option,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.onPrimary(context)
                                  : AppColors.primaryText(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}