import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bouton primaire "Ajouter au panier" - pill pleine largeur, fond teal foncé.
class AddToCartButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  final bool isLoading;

  const AddToCartButton({
    super.key,
    required this.onTap,
    this.label = 'Ajouter au panier',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary(context),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation(
                      AppColors.onPrimary(context),
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 20,
                      color: AppColors.onPrimary(context),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary(context),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}