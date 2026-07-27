import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Notifications/Helpers/NotificationVisual.dart';
import 'package:connectia/Features/Notifications/data/models/NotificationModel.dart';
import 'package:flutter/material.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visual = NotificationHelper.getVisual(context, notification.type);

    final title = notification.customTitle ?? visual.defaultTitle;
    final message = notification.customMessage ?? visual.defaultMessage;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: notification.isRead
            ? Colors.transparent
            : AppColors.accent20(context).withValues(alpha: 0.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône ronde colorée
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: visual.iconBgColor,
              ),
              child: Icon(visual.icon, color: visual.iconColor, size: 22),
            ),
            const SizedBox(width: 12),

            // Titre + message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.5,
                            color: AppColors.primaryText(context),
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6, top: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary(context),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.secondary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(notification.date),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.secondary(context).withValues(alpha: 0.8),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return '${date.day}/${date.month}/${date.year}';
  }
}