import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/widgets/Buttons/CircleIconActionButton.dart';
import 'package:flutter/material.dart';

/// Boutons d'action : Supprimer (rouge) + Modifier + Acheter (primary).
/// Tous affichés en icônes uniquement, dans des cercles.
class OrderActionButtons extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onBuy;
  final bool isLoading;

  const OrderActionButtons({
    super.key,
    required this.onDelete,
    required this.onEdit,
    required this.onBuy,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Bouton Supprimer — icône rouge
        CircleIconActionButton(
          icon: Icons.delete_outline,
          color: AppColors.wishlist(context),
          backgroundColor: AppColors.wishlist(context).withValues(alpha: 0.12),
          borderColor: AppColors.wishlist(context).withValues(alpha: 0.4),
          onTap: isLoading ? null : onDelete,
        ),
        const SizedBox(width: 12),

        // Bouton Modifier — icône neutre
        CircleIconActionButton(
          icon: Icons.edit_outlined,
          color: AppColors.primary(context),
          backgroundColor: AppColors.accent20(context),
          borderColor: AppColors.primary(context).withValues(alpha: 0.4),
          onTap: isLoading ? null : onEdit,
        ),
        const SizedBox(width: 12),

        // Bouton Acheter — rempli, couleur primary
        Expanded(
          child: CircleIconActionButton(
            icon: Icons.shopping_bag_outlined,
            color: AppColors.onPrimary(context),
            backgroundColor: AppColors.primary(context),
            borderColor: Colors.transparent,
            expanded: true,
            isLoading: isLoading,
            onTap: isLoading ? null : onBuy,
          ),
        ),
      ],
    );
  }
}
