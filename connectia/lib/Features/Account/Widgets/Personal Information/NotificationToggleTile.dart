import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

/// Tuile de préférence avec toggle (ex: Emails marketing, Notifications push...).
class NotificationToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const NotificationToggleTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.softBg(context),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryText(context), size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.primaryText(context),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.secondary(context),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: isActive,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: AppColors.primary(context),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: AppColors.secondary(context).withValues(alpha: 0.4),
        ),
      ],
    );
  }
}

/// Exemple d'utilisation :
///
