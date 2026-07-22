import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

/// Barre d'en-tête de la Home : salutation + nom + icône notifications.
class HomeHeaderBar extends StatelessWidget {
  final String userName;
  final int notificationCount;
  final VoidCallback onNotificationTap;
  final String? avatarUrl;

  const HomeHeaderBar({
    super.key,
    required this.userName,
    required this.notificationCount,
    required this.onNotificationTap,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.accent20(context),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? Icon(Icons.person, color: AppColors.primary(context))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salut,',
                  style: TextStyle(color: AppColors.secondary(context), fontSize: 13),
                ),
                Text(
                  '$userName 👋',
                  style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          _NotificationButton(
            count: notificationCount,
            onTap: onNotificationTap,
          ),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _NotificationButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.secondary(context).withValues(alpha: 0.15),
              ),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primaryText(context),
            ),
          ),
          if (count > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.wishlist(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.background(context), width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 18),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}