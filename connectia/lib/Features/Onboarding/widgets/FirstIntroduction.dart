import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Firstintroduction extends StatelessWidget {
  const Firstintroduction({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      color: AppColors.defaultBase,
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/FirstIntro.svg',
            width: size.width * 0.6,
            height: size.width * 0.6,
          ),
          SizedBox(height: size.height * 0.04),
          Text(
            'Bienvenue sur Connectia',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBrand,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Trouvez les meilleures offres auprès des meilleurs vendeurs, réunis en un seul endroit.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
