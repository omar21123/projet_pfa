import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

class SocialAccountRow extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? username; // null/empty when not connected
  final bool isConnected;
  final bool enabled; // false => action shown but greyed out, non-tappable
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const SocialAccountRow({
    super.key,
    required this.icon,
    required this.title,
    this.username,
    required this.isConnected,
    this.enabled = true,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final actionLabel = isConnected ? 'Déconnecter' : 'Connecter';
    final actionColor = !enabled
        ? AppColors.secondary(context)
        : isConnected
            ? AppColors.logout(context)
            : AppColors.primary(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(width: 36, height: 36, child: icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isConnected ? (username ?? '') : 'Non connecté',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: isConnected ? FontStyle.normal : FontStyle.italic,
                    color: AppColors.secondary(context),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: !enabled
                ? null
                : isConnected
                    ? onDisconnect
                    : onConnect,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Text(
                actionLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: actionColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card wrapper that lays out multiple SocialAccountRow with dividers,
/// matching the rounded card look from the app.
class SocialAccountsCard extends StatelessWidget {
  final List<SocialAccountRow> rows;

  const SocialAccountsCard({super.key, required this.rows});

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
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: AppColors.secondary(context).withValues(alpha: 0.15),
              ),
          ],
        ],
      ),
    );
  }
}