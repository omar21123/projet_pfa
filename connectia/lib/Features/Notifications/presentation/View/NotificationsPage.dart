import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Notifications/data/models/NotificationModel.dart';
import 'package:connectia/Features/Notifications/enums/NotificationType.dart';
import 'package:connectia/Features/Notifications/presentation/widgets/NotificationTile.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Remplace par tes données réelles (API, Provider, Bloc...)
  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: '1',
      type: NotificationType.livreurWaiting,
      date: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    NotificationModel(
      id: '2',
      type: NotificationType.orderOnTheWay,
      date: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
    NotificationModel(
      id: '3',
      type: NotificationType.orderAccepted,
      date: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: true,
    ),
    NotificationModel(
      id: '4',
      type: NotificationType.paymentSuccess,
      date: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: true,
    ),
    NotificationModel(
      id: '5',
      type: NotificationType.newAccountRegistered,
      date: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _notifications.any((n) => !n.isRead)
                ? _markAllAsRead
                : null,
            child: Text(
              'Tout marquer comme lu',
              style: TextStyle(
                color: AppColors.primary(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: AppColors.secondary(context).withValues(alpha: 0.15),
              ),
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return NotificationTile(
                  notification: notification,
                  onTap: () => _onNotificationTap(notification),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 56,
            color: AppColors.secondary(context),
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune notification pour le moment',
            style: TextStyle(color: AppColors.secondary(context)),
          ),
        ],
      ),
    );
  }

  void _onNotificationTap(NotificationModel notification) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    });
    // Navigation selon notification.type (vers la commande, le profil, etc.)
  }

  void _markAllAsRead() {
    setState(() {
      for (var i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    });
  }
}