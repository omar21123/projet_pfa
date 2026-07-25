import 'package:connectia/Features/Notifications/enums/NotificationType.dart';
import 'package:flutter/material.dart';
import 'package:connectia/Core/Constants/AppColors.dart';

/// Regroupe l'icône, les couleurs et le message par défaut
/// associés à chaque [NotificationType].
class NotificationVisual {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String defaultTitle;
  final String defaultMessage;

  const NotificationVisual({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.defaultTitle,
    required this.defaultMessage,
  });
}

/// Fournit la logique visuelle (icône, couleurs, message) selon le
/// [NotificationType], en s'appuyant sur les couleurs sémantiques
/// déjà définies dans [AppColors].
class NotificationHelper {
  NotificationHelper._();

  static NotificationVisual getVisual(
    BuildContext context,
    NotificationType type,
  ) {
    switch (type) {
      case NotificationType.orderAccepted:
        return NotificationVisual(
          icon: Icons.check_circle_outline,
          iconColor: AppColors.successColor(context),
          iconBgColor: AppColors.successColorBg(context),
          defaultTitle: 'Commande acceptée',
          defaultMessage: 'Votre commande a été acceptée et est en cours de préparation.',
        );

      case NotificationType.orderPreparing:
        return NotificationVisual(
          icon: Icons.restaurant_menu_outlined,
          iconColor: AppColors.loyalty(context),
          iconBgColor: AppColors.loyaltyBg(context),
          defaultTitle: 'Commande en préparation',
          defaultMessage: 'Votre commande est en cours de préparation.',
        );

      case NotificationType.orderOnTheWay:
        return NotificationVisual(
          icon: Icons.delivery_dining_outlined,
          iconColor: AppColors.primary(context),
          iconBgColor: AppColors.accent20(context),
          defaultTitle: 'Commande en route',
          defaultMessage: 'Votre livreur est en route avec votre commande.',
        );

      case NotificationType.orderDelivered:
        return NotificationVisual(
          icon: Icons.task_alt,
          iconColor: AppColors.successColor(context),
          iconBgColor: AppColors.successColorBg(context),
          defaultTitle: 'Commande livrée',
          defaultMessage: 'Votre commande a bien été livrée. Bon appétit !',
        );

      case NotificationType.orderCancelled:
        return NotificationVisual(
          icon: Icons.cancel_outlined,
          iconColor: AppColors.wishlist(context),
          iconBgColor: AppColors.wishlistBg(context),
          defaultTitle: 'Commande annulée',
          defaultMessage: 'Votre commande a été annulée.',
        );

      case NotificationType.livreurWaiting:
        return NotificationVisual(
          icon: Icons.timer_outlined,
          iconColor: AppColors.likedProducts(context),
          iconBgColor: AppColors.likedProductsBg(context),
          defaultTitle: 'Le livreur vous attend',
          defaultMessage: 'Votre livreur est arrivé et vous attend en bas.',
        );

      case NotificationType.livreurArrived:
        return NotificationVisual(
          icon: Icons.pin_drop_outlined,
          iconColor: AppColors.primary(context),
          iconBgColor: AppColors.accent20(context),
          defaultTitle: 'Livreur arrivé',
          defaultMessage: 'Votre livreur est arrivé à l\'adresse de livraison.',
        );

      case NotificationType.paymentSuccess:
        return NotificationVisual(
          icon: Icons.payments_outlined,
          iconColor: AppColors.successColor(context),
          iconBgColor: AppColors.successColorBg(context),
          defaultTitle: 'Paiement réussi',
          defaultMessage: 'Votre paiement a été effectué avec succès.',
        );

      case NotificationType.paymentFailed:
        return NotificationVisual(
          icon: Icons.error_outline,
          iconColor: AppColors.wishlist(context),
          iconBgColor: AppColors.wishlistBg(context),
          defaultTitle: 'Échec du paiement',
          defaultMessage: 'Votre paiement n\'a pas pu être traité. Réessayez.',
        );

      case NotificationType.newAccountRegistered:
        return NotificationVisual(
          icon: Icons.person_add_alt_1_outlined,
          iconColor: AppColors.security(context),
          iconBgColor: AppColors.securityBg(context),
          defaultTitle: 'Nouveau compte créé',
          defaultMessage: 'Un nouveau compte a été enregistré avec succès.',
        );

      case NotificationType.promoOffer:
        return NotificationVisual(
          icon: Icons.local_offer_outlined,
          iconColor: AppColors.loyalty(context),
          iconBgColor: AppColors.loyaltyBg(context),
          defaultTitle: 'Offre spéciale',
          defaultMessage: 'Une nouvelle offre vous attend, n\'en ratez rien !',
        );

      case NotificationType.general:
        return NotificationVisual(
          icon: Icons.notifications_none_outlined,
          iconColor: AppColors.neutral(context),
          iconBgColor: AppColors.neutralBg(context),
          defaultTitle: 'Notification',
          defaultMessage: 'Vous avez une nouvelle notification.',
        );
    }
  }
}