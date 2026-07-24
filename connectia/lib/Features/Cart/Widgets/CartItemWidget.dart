import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Cart/Widgets/PaymentMethodTile.dart';
import 'package:connectia/Features/Cart/Widgets/ProductConfigsPanel.dart';
import 'package:connectia/Features/Cart/Widgets/ProductSummaryCard.dart';
import 'package:connectia/Features/Cart/Widgets/QuantityStepperCard.dart';
import 'package:connectia/Features/Cart/data/Models/OptionChoosesConfig.dart';
import 'package:connectia/Features/Home/data/Models/ProductConfig.dart';
import 'package:flutter/material.dart';

class Cartitemwidget extends StatelessWidget {
  const Cartitemwidget({super.key});
  // Exemple de liste de configurations sélectionnées
  final List<OptionChoosesConfig> selectedOptions = const [
    OptionChoosesConfig(configName: 'Couleur', optionName: 'Rouge'),
    OptionChoosesConfig(configName: 'Taille', optionName: 'M'),
    OptionChoosesConfig(configName: 'Matière', optionName: 'Coton bio'),
  ];
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent30(context), width: 1.2),
      ),
      child: Column(
        children: [
          ProductSummaryCard(
            imageUrl:
                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQAPf_062JKWOBQr9rKxfyjLtlwzCn6Wwx_fJ6vQDIAgQ&s=10',
            price: '1900 MAD',
            title:
                'Image Stock Photos, Images and Backgrounds for Free Download',
          ),
          ProductConfigsPanel(options: selectedOptions),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: QuantityStepperCard(
              initialValue: 1,
              max: 10,
              onChanged: (qty) {},
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: PaymentMethodTile(
              method: PaymentMethod.online,
              selected: true,
            ),
          ),
        ],
      ),
    );
  }
}
