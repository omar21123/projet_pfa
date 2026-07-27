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
      child: PhysicalModel(
        shape: BoxShape.circle,
        elevation: 8,
        shadowColor: AppColors.wishlistBg(context),
        color: AppColors.primary(context),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.softBg(context),
            shape: BoxShape.circle,
          ),
          child: Center(child: Icon(icon, size: 20, color: color)),
        ),
      ),
    );
  }
}
