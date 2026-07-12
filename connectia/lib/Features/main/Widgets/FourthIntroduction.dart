import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Fourthintroduction extends StatelessWidget {
  const Fourthintroduction({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      color: AppColors.background(context),
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/FourthIntro.svg',
            width: size.width * 0.6,
            height: size.width * 0.6,
          ),
          SizedBox(height: size.height * 0.04),
          Text(
            'Payez en toute sérénité',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary(context),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Paiement en ligne (Visa, Mastercard), PayPal, Payoneer ou paiement à la livraison : c\'est le vendeur qui choisit les options disponibles, et vous choisissez celle qui vous convient — sans aucun frais supplémentaire.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              color: AppColors.secondary(context),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Votre paiement reste protégé pendant 14 jours. Si vous ne recevez pas votre commande, vous pouvez demander un remboursement.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.primary(context),
            ),
          ),
        ],
      ),
    );
  }
}
