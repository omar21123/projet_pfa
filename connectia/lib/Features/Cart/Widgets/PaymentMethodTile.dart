import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Home/data/Models/ProductConfig.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Métadonnées d'affichage associées à chaque [PaymentMethod].
class _PaymentMethodInfo {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PaymentMethodInfo({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

extension PaymentMethodX on PaymentMethod {
  _PaymentMethodInfo get info {
    switch (this) {
      case PaymentMethod.cod:
        return const _PaymentMethodInfo(
          icon: Icons.payments_outlined,
          title: 'Paiement: À la livraison',
          subtitle: 'Payez en espèces dès réception',
        );
      case PaymentMethod.online:
        return const _PaymentMethodInfo(
          icon: Icons.credit_card,
          title: 'Paiement: En ligne',
          subtitle: 'Payez maintenant par carte bancaire',
        );
    }
  }
}

class PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback? onTap;

  const PaymentMethodTile({
    super.key,
    required this.method,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final info = method.info;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MODE DE PAIEMENT',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.secondary(context),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.softBg(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? AppColors.primary(context)
                    : AppColors.secondary(context).withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                // Icône ronde
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    info.icon,
                    color: AppColors.onPrimary(context),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Titre + sous-titre
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.primaryText(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        info.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.secondary(context),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Coche de sélection
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? AppColors.primary(context)
                        : AppColors.surfaceAlt(context),
                    border: selected
                        ? null
                        : Border.all(
                            color: AppColors.secondary(
                              context,
                            ).withValues(alpha: 0.4),
                          ),
                  ),
                  child: selected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: AppColors.onPrimary(context),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
