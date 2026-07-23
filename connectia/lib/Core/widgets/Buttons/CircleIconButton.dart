import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const CircleIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.softBg(context),
          shape: BoxShape.circle,
        ),
        child: Center(child: Icon(icon, size: 30, color: color)),
      ),
    );
  }
}
