import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Home/data/Models/ProductConfig.dart';
import 'package:flutter/material.dart';

/// Badges des moyens de paiement acceptés (informatif, non sélectionnable
/// -> le choix du moyen de paiement se fait au checkout, pas ici).
class PaymentMethodBadges extends StatelessWidget {
  final List<PaymentMethod> methods;

  const PaymentMethodBadges({super.key, required this.methods});

  IconData _iconFor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cod:
        return Icons.local_shipping_outlined;
      case PaymentMethod.online:
        return Icons.credit_card_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (methods.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: methods
          .map(
            (method) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.successColorBg(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_iconFor(method), size: 15, color: AppColors.successColor(context)),
                  const SizedBox(width: 6),
                  Text(
                    method.label,
                    style: TextStyle(
                      color: AppColors.successColor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}