
import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Account/Widgets/Pref/SectionCard.dart';
import 'package:connectia/Features/Account/Widgets/Pref/SectionHeader.dart';
import 'package:flutter/material.dart';

class CurrencySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(icon: Icons.attach_money, title: 'Devise'),
          const SizedBox(height: 4),
          Text(
            "Devise utilisée pour tous les prix affichés dans l'application.",
            style: TextStyle(
              color: AppColors.secondary(context),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent20(context),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  'DH',
                  style: TextStyle(
                    color: AppColors.primary(context),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Dirham marocain (MAD)',
                  style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.check_circle, color: AppColors.primary(context), size: 20),
            ],
          ),
        ],
      ),
    );
  }
}