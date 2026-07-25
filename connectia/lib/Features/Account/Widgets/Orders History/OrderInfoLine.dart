import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

/// Icône + texte sur une seule ligne — utilisé pour "Ville : ..." et
/// "Livraison estimée : ...".
class OrderInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const OrderInfoLine({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.secondary(context)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: AppColors.secondary(context)),
          ),
        ),
      ],
    );
  }
}