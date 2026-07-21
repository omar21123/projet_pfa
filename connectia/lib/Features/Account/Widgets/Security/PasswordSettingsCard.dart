import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

class PasswordSettingsCard extends StatelessWidget {
  final bool hasPassword;
  final String? lastModifiedLabel; // only relevant when hasPassword == true
  final VoidCallback onChangePassword;
  final VoidCallback onCreatePassword;

  const PasswordSettingsCard({
    super.key,
    required this.hasPassword,
    this.lastModifiedLabel,
    required this.onChangePassword,
    required this.onCreatePassword,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.securityBg(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasPassword ? Icons.lock_reset_rounded : Icons.lock_outline_rounded,
                  color: AppColors.security(context),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mot de passe',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasPassword
                          ? 'Dernière modification ${lastModifiedLabel ?? ''}'
                          : 'Vous n\'avez pas encore défini de mot de passe',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.secondary(context),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: hasPassword ? onChangePassword : onCreatePassword,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasPassword ? 'Modifier le mot de passe' : 'Créer un mot de passe',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary(context),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.primary(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}