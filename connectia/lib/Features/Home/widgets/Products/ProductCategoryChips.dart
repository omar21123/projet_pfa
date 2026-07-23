import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

/// Chips catégories (lecture seule) sur la page détail produit.
class ProductCategoryChips extends StatelessWidget {
  final List<String> categories;

  const ProductCategoryChips({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories
          .map(
            (category) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.neutralBg(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: AppColors.neutral(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}