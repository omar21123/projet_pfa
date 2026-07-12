import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Secondintroduction extends StatelessWidget {
  const Secondintroduction({super.key});

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
            'assets/images/SecondIntro.svg',
            width: size.width * 0.6,
            height: size.width * 0.6,
          ),
          SizedBox(height: size.height * 0.04),
          Text(
            'Des produits de confiance',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary(context),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Qualité vérifiée, quantité disponible, de nombreuses catégories et une multitude d\'options. Grâce à nos filtres avancés, trouvez exactement le produit que vous imaginez.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              color: AppColors.secondary(context),
            ),
          ),
        ],
      ),
    );
  }
}
