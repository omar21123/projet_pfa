import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

/// Tuile "Email / Téléphone..." avec statut de vérification.
///
/// - `isVerified = true`  -> affiche le badge "Vérifié" (non tappable).
/// - `isVerified = false` -> affiche un bouton "Vérifier". `onVerifyTap`
///   n'est utilisé que dans ce cas.
class VerifiableInfoTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color itemBackgroundColor;
  final bool isVerified;

  /// Appelé uniquement quand [isVerified] est false (tap sur "Vérifier").
  final VoidCallback? onVerifyTap;

  const VerifiableInfoTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.itemBackgroundColor,
    required this.isVerified,
    this.onVerifyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: itemBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary(context).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,

            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.secondary(context),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          isVerified
              ? _buildVerifiedBadge(context)
              : _buildVerifyButton(context),
        ],
      ),
    );
  }

  Widget _buildVerifiedBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.successColorBg(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.successColor(context),
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            'Vérifié',
            style: TextStyle(
              color: AppColors.successColor(context),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton(BuildContext context) {
    return InkWell(
      onTap: onVerifyTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Vérifier',
          style: TextStyle(
            color: AppColors.onPrimary(context),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
