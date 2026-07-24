import 'package:connectia/Core/Constants/AppColors.dart';
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
        _CircleIconButton(
          icon: Icons.delete_outline,
          color: AppColors.wishlist(context),
          backgroundColor: AppColors.wishlist(context).withValues(alpha: 0.12),
          borderColor: AppColors.wishlist(context).withValues(alpha: 0.4),
          onTap: isLoading ? null : onDelete,
        ),
        const SizedBox(width: 12),

        // Bouton Modifier — icône neutre
        _CircleIconButton(
          icon: Icons.edit_outlined,
          color: AppColors.primary(context),
          backgroundColor: AppColors.accent20(context),
          borderColor: AppColors.primary(context).withValues(alpha: 0.4),
          onTap: isLoading ? null : onEdit,
        ),
        const SizedBox(width: 12),

        // Bouton Acheter — rempli, couleur primary
        Expanded(
          child: _CircleIconButton(
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

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback? onTap;
  final bool expanded;
  final bool isLoading;

  const _CircleIconButton({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
    this.expanded = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: expanded ? null : 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: expanded ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: expanded ? BorderRadius.circular(14) : null,
          color: backgroundColor,
          border: Border.all(color: borderColor),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(icon, color: color),
      ),
    );
  }
}
