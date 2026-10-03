import 'package:flutter/material.dart';

/// Badge de statut coloré.
class OrderStatusBadge extends StatelessWidget {
  final String statusCode;
  const OrderStatusBadge({super.key, required this.statusCode});

  Color _backgroundColor() {
    switch (statusCode.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFFFF3CD);
      case 'PREPARING':
        return const Color(0xFFD6ECFB);
      case 'SHIPPED':
        return const Color(0xFFD3E4FD);
      case 'DELIVERED':
        return const Color(0xFFFCE3D0);
      case 'CANCELLED':
        return const Color(0xFFFBD5D5);
      default:
        return const Color(0xFFF0F0F0);
    }
  }

  Color _foregroundColor() {
    switch (statusCode.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFF8A6D1E);
      case 'PREPARING':
        return const Color(0xFF1D5B8A);
      case 'SHIPPED':
        return const Color(0xFF1E4FA0);
      case 'DELIVERED':
        return const Color(0xFFB05A1E);
      case 'CANCELLED':
        return const Color(0xFFA32626);
      default:
        return const Color(0xFF666666);
    }
  }

  String get _label {
    switch (statusCode.toUpperCase()) {
      case 'PENDING':
        return 'En attente';
      case 'PREPARING':
        return 'En préparation';
      case 'SHIPPED':
        return 'Expédiée';
      case 'DELIVERED':
        return 'Livrée';
      case 'CANCELLED':
        return 'Annulée';
      default:
        return statusCode;
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
        _label,
        style: TextStyle(
          color: _foregroundColor(),
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
