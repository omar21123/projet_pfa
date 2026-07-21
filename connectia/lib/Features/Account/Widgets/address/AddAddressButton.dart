import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

class AddAddressButton extends StatelessWidget {
  final VoidCallback onTap;

  const AddAddressButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.primary(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: AppColors.onPrimary(context), size: 18),
              const SizedBox(width: 4),
              Text(
                'Ajouter',
                style: TextStyle(
                  color: AppColors.onPrimary(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
