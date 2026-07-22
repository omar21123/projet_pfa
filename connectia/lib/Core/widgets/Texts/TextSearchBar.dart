import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

class Textsearchbar extends StatelessWidget {
  const Textsearchbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          style: TextStyle(color: AppColors.primaryText(context)),
          decoration: InputDecoration(
            hintText: 'Rechercher un produit, une marque...',
            hintStyle: TextStyle(color: AppColors.secondary(context)),
            prefixIcon: Icon(Icons.search, color: AppColors.secondary(context)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
