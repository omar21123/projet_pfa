import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

/// Widget "Récapitulatif final" avec le total à payer.
class OrderTotalSummary extends StatelessWidget {
  final double total;
  final String currency;

  const OrderTotalSummary({
    super.key,
    required this.total,
    this.currency = 'MAD',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Ligne de séparation supérieure
        Divider(
          color: AppColors.secondary(context).withValues(alpha: 0.25),
          height: 1,
        ),
        const SizedBox(height: 12),

        // Label "Récapitulatif final"
        Text(
          'Récapitulatif final',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.secondary(context),
          ),
        ),
        const SizedBox(height: 6),

        // "Total: 1,499.00 MAD"
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Total: ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryText(context),
                ),
              ),
              TextSpan(
                text: '${_formatAmount(total)} $currency',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Formate le montant avec séparateur de milliers (1499.0 -> "1,499.00")
  String _formatAmount(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i != 0 && (intPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(intPart[i]);
    }
    return '${buffer.toString()}.$decPart';
  }
}