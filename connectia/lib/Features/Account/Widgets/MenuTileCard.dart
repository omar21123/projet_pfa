import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

class MenuTileCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color? iconColorDark;
  final Color? iconBackgroundColorDark;

  final double borderRadius;
  final VoidCallback? onTap;

  const MenuTileCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    this.iconColorDark,
    this.iconBackgroundColorDark,
    this.borderRadius = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final resolvedIconColor = isDark ? (iconColorDark ?? iconColor) : iconColor;
    final resolvedIconBg = isDark
        ? (iconBackgroundColorDark ?? iconColor.withValues(alpha: 0.20))
        : iconBackgroundColor;

    return Material(
      color: AppColors.surface(context),
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: resolvedIconBg,
                  borderRadius: BorderRadius.circular(borderRadius * 0.7),
                ),
                child: Icon(icon, color: resolvedIconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.secondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.secondary(context),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
