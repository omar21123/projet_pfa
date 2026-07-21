import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

/// Bloc "Identifiant public" + "Méthode de connexion".
///
/// - `hasPassword = true`  -> l'utilisateur s'est inscrit avec e-mail +
///   mot de passe, modifiable depuis Sécurité.
/// - `hasPassword = false` -> pas de mot de passe défini, connexion via
///   un fournisseur externe (Google / Facebook / Apple).
class AccountAccessInfo extends StatelessWidget {
  final String publicId;
  final bool hasPassword;

  /// Tap sur la ligne "Méthode de connexion" (ex: ouvrir Sécurité pour
  /// définir/modifier le mot de passe). Optionnel.
  final VoidCallback? onConnectionMethodTap;

  const AccountAccessInfo({
    super.key,
    required this.publicId,
    required this.hasPassword,
    this.onConnectionMethodTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(
          icon: Icons.badge_outlined,
          label: 'Identifiant public',
          value: publicId,
          monospace: true,
        ),
        Divider(
          height: 32,
          color: AppColors.secondary(context).withValues(alpha: 0.15),
        ),
        _InfoRow(
          icon: hasPassword ? Icons.lock_outline : Icons.link,
          label: 'Méthode de connexion',
          value: hasPassword
              ? 'Mot de passe défini'
              : 'Connecté via un fournisseur externe',
          onTap: onConnectionMethodTap,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool monospace;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.secondary(context), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.secondary(context),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 15,
                      fontFamily: monospace ? 'monospace' : null,
                      letterSpacing: monospace ? 1.1 : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
