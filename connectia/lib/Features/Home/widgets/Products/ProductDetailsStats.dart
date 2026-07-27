import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Carte "stats produit" (note / ventes / favoris) façon pill blanche,
/// avec séparateurs verticaux entre chaque stat.
class ProductDetailsStats extends StatelessWidget {
  final String rating; // ex: "4.9"
  final String sales; // ex: "2.4k+"
  final String favorites; // ex: "842"

  const ProductDetailsStats({
    super.key,
    required this.rating,
    required this.sales,
    required this.favorites,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.bookmark_border,
              value: rating,
              label: 'Wishlists',
            ),
          ),
          _Divider(context: context),
          Expanded(
            child: _StatItem(
              icon: Icons.shopping_bag_outlined,
              value: sales,
              label: 'Ventes',
            ),
          ),
          _Divider(context: context),
          Expanded(
            child: _StatItem(
              icon: Icons.favorite_border_rounded,
              value: favorites,
              label: 'Favoris',
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final BuildContext context;

  const _Divider({required this.context});

  @override
  Widget build(BuildContext _) {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.secondary(context).withValues(alpha: 0.2),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: AppColors.primary(context)),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryText(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.secondary(context),
          ),
        ),
      ],
    );
  }
}
