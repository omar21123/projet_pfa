import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

class OrderHistoryEmptyState extends StatelessWidget {
  const OrderHistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 72,
              color: AppColors.secondary(context).withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune commande pour le moment',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos commandes passées apparaîtront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.secondary(context),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: naviguer vers la page d'accueil / produits.
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(context),
                foregroundColor: AppColors.onPrimary(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Découvrir des produits',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}