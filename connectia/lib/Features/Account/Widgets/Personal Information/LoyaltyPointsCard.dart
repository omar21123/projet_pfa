import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

/// Carte "Points de fidélité".
class LoyaltyPointsCard extends StatelessWidget {
  final int points;
  final VoidCallback? onTap;

  const LoyaltyPointsCard({super.key, required this.points, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.loyaltyCardBackground(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.loyaltyBorderColor(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.loyaltyBg(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events,
                color: AppColors.loyalty(context),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Points de fidélité',
                    style: TextStyle(
                      color: AppColors.loyaltyTextColor(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$points',
                        style: TextStyle(
                          color: AppColors.loyaltyTextColor(context),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'pts',
                        style: TextStyle(
                          color: AppColors.loyaltyTextColor(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.loyalty(context),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// Exemple d'utilisation :
///
