import 'package:connectia/Features/Notifications/enums/NotificationType.dart';

class NotificationModel {
  final String id;
  final NotificationType type;
  final DateTime date;
  final bool isRead;

  /// Optionnel : si non fourni, on utilise le titre/message par défaut
  /// défini dans [NotificationHelper].
  final String? customTitle;
  final String? customMessage;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.date,
    this.isRead = false,
    this.customTitle,
    this.customMessage,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      type: type,
      date: date,
      isRead: isRead ?? this.isRead,
      customTitle: customTitle,
      customMessage: customMessage,
    );
  }
}