import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Home/data/Models/CategoryModel.dart';
import 'package:flutter/material.dart';

///圆形 category card — displays name + icon/image with a children count badge.
class CategoryCard extends StatelessWidget {
  final NavbarCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent20(context),
                      border: isSelected
                          ? Border.all(
                              color: AppColors.primary(context), width: 2.5)
                          : null,
                    ),
                    child: ClipOval(
                      child: category.iconUrl != null &&
                              category.iconUrl!.isNotEmpty
                          ? Image.network(
                              category.iconUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildIcon(context),
                            )
                          : _buildIcon(context),
                    ),
                  ),
                  if (category.hasChildren)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary(context),
                          border: Border.all(
                            color: AppColors.background(context),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${category.children.length}',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primary(context)
                    : AppColors.primaryText(context),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return Icon(
      Icons.category_outlined,
      color: AppColors.primary(context),
      size: 28,
    );
  }
}

/// Horizontal scrollable section of category cards.
class CategoriesSection extends StatelessWidget {
  final List<NavbarCategory> categories;
  final int? selectedCategoryId;
  final ValueChanged<int> onCategoryTap;

  const CategoriesSection({
    super.key,
    required this.categories,
    required this.onCategoryTap,
    this.selectedCategoryId,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return CategoryCard(
            category: category,
            isSelected: category.id == selectedCategoryId,
            onTap: () => onCategoryTap(category.id),
          );
        },
      ),
    );
  }
}
