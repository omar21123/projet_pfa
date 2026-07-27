import 'package:connectia/Features/Account/data/Models/OrderModel.dart';
import 'package:flutter/material.dart';

/// Badge de statut coloré.
///
/// TODO: ces couleurs sont codées en dur ici plutôt que dans AppColors
/// car ce sont des couleurs "sémantiques de statut" (pas de thème clair/
/// sombre à gérer, elles restent fixes). Si AppColors gère déjà ce genre
/// de palette ailleurs, les migrer là-bas pour centraliser.
class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;
  const OrderStatusBadge({super.key, required this.status});

  Color _backgroundColor() {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFFFF3CD);
      case OrderStatus.preparing:
        return const Color(0xFFD6ECFB);
      case OrderStatus.shipped:
        return const Color(0xFFD3E4FD);
      case OrderStatus.delivered:
        return const Color(0xFFFCE3D0);
      case OrderStatus.cancelled:
        return const Color(0xFFFBD5D5);
    }
  }

  Color _foregroundColor() {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFF8A6D1E);
      case OrderStatus.preparing:
        return const Color(0xFF1D5B8A);
      case OrderStatus.shipped:
        return const Color(0xFF1E4FA0);
      case OrderStatus.delivered:
        return const Color(0xFFB05A1E);
      case OrderStatus.cancelled:
        return const Color(0xFFA32626);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _foregroundColor(),
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}