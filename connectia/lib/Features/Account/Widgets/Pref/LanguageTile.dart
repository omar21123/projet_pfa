import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

class LanguageTile extends StatelessWidget {
  final String flag;
  final String label;
  final bool enabled;

  const LanguageTile({
    required this.flag,
    required this.label,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = enabled
        ? AppColors.primaryText(context)
        : AppColors.secondary(context);

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: enabled ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (enabled)
            Icon(Icons.check_circle, color: AppColors.primary(context), size: 20)
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.softBg(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Bientôt',
                style: TextStyle(
                  color: AppColors.secondary(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
