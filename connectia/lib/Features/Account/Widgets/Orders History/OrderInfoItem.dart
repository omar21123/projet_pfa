import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

/// Icône + libellé + valeur empilés — utilisé pour les blocs
/// "Livreur" / "Tracking" côte à côte dans OrderCard.
class OrderInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const OrderInfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.secondary(context)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.secondary(context),
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}