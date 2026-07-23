import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/widgets/Buttons/StatChip.dart';
import 'package:flutter/material.dart';

/// Carte statistiques : commandes totales / likes / wishlists.
class ProductStatsCard extends StatelessWidget {
  final int totalOrders;
  final int totalLikes;
  final int totalWishlists;

  const ProductStatsCard({
    super.key,
    required this.totalOrders,
    required this.totalLikes,
    required this.totalWishlists,
  });

  static String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          StatChip(
            icon: Icons.shopping_bag_outlined,
            value: _formatCount(totalOrders),
          ),
          StatChip(
            icon: Icons.favorite_border,
            value: _formatCount(totalLikes),
          ),
          StatChip(
            icon: Icons.bookmark_border,
            value: _formatCount(totalWishlists),
          ),
        ],
      ),
    );
  }
}