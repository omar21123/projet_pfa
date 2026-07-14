import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomIconButton extends StatelessWidget {
  const CustomIconButton({
    super.key,
    required this.iconPath,
    required this.title,
    this.onPressed,
    this.backgroundColor,
    this.borderColor,
    this.titleColor,
    this.iconSize = 28,
    this.borderRadius = 16,
  });

  final String iconPath; // path to the SVG asset
  final String title;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? titleColor;
  final double iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.surface(context);
    final border = borderColor ?? AppColors.secondary(context).withValues(alpha: 0.4);
    final textColor = titleColor ?? AppColors.primaryText(context);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: border, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                iconPath,
                width: iconSize,
                height: iconSize,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}