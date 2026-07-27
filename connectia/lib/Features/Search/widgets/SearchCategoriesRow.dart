import 'package:connectia/Features/Search/widgets/SearchCategoryChip.dart';
import 'package:flutter/material.dart';

/// Liste horizontale de chips catégories.
class SearchCategoriesRow extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String> onSelected;

  const SearchCategoriesRow({
    super.key,
    required this.categories,
    required this.onSelected,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          return SearchCategoryChip(
            label: category,
            isSelected: category == selected,
            onTap: () => onSelected(category),
          );
        },
      ),
    );
  }
}
