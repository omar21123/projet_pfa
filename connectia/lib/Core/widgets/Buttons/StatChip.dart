
import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

class StatChip extends StatelessWidget {
  final IconData icon;
  final String value;

  const StatChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.secondary(context)),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(color: AppColors.secondary(context), fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}