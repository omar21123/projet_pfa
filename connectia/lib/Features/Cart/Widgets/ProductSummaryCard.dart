import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Carte "résumé produit" compacte : image + titre + prix, bordure fine
/// teal translucide. Utilisée en tête d'un panneau panier/checkout.
class ProductSummaryCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String price;

  const ProductSummaryCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 56,
              height: 56,
              color: AppColors.softBg(context),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Padding(
                    padding: const EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      valueColor: AlwaysStoppedAnimation(
                        AppColors.primary(context),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.camera_alt_outlined,
                  size: 22,
                  color: AppColors.secondary(context),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  price,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
