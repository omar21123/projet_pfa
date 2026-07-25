import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/functions/Frenchdateformatter.dart';
import 'package:connectia/Features/Account/Widgets/Orders%20History/OrderInfoItem.dart';
import 'package:connectia/Features/Account/Widgets/Orders%20History/OrderInfoLine.dart';
import 'package:connectia/Features/Account/Widgets/Orders%20History/OrderStatusBadge.dart';
import 'package:connectia/Features/Account/data/Models/OrderModel.dart';
import 'package:flutter/material.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const OrderCard({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 4),
          Text(
            order.productName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.primaryText(context),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              order.productImageUrl,
              height: 110,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 110,
                color: AppColors.accent20(context),
                alignment: Alignment.center,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.secondary(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildContextualInfo(context),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: AppColors.secondary(context).withValues(alpha: 0.15),
          ),
          const SizedBox(height: 10),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '#${order.id}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.primaryText(context),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '·',
                style: TextStyle(color: AppColors.secondary(context)),
              ),
              const SizedBox(width: 6),
              Text(
                formatFrenchDate(order.createdDate),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.secondary(context),
                ),
              ),
            ],
          ),
        ),
        OrderStatusBadge(status: order.status),
      ],
    );
  }

  /// Le bloc affiché dépend des infos dispo sur la commande : livreur
  /// assigné, livraison en cours, ou déjà livrée avec une ville connue.
  Widget _buildContextualInfo(BuildContext context) {
    if (order.livreurName != null && order.trackingNumber != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: OrderInfoItem(
                icon: Icons.delivery_dining_outlined,
                label: 'Livreur',
                value: order.livreurName!,
              ),
            ),
            Expanded(
              child: OrderInfoItem(
                icon: Icons.qr_code_2_outlined,
                label: 'Tracking',
                value: order.trackingNumber!,
              ),
            ),
          ],
        ),
      );
    }

    if (order.estimatedDeliveryDate != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OrderInfoLine(
            icon: Icons.schedule_outlined,
            text:
                'Livraison estimée : ${formatFrenchDate(order.estimatedDeliveryDate!)}',
          ),
          const SizedBox(height: 4),
          Text(
            'Paiement : ${order.paymentMethod.label}',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.secondary(context),
            ),
          ),
        ],
      );
    }

    if (order.ville != null) {
      return OrderInfoLine(
        icon: Icons.location_on_outlined,
        text: 'Ville : ${order.ville}',
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total (${order.itemCount} article${order.itemCount > 1 ? 's' : ''}) • ${order.paymentMethod.label}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.secondary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                // Formatage simple, cohérent avec ProductCard (pas de
                // séparateur de milliers). Pour "1 499,00 MAD" à la
                // française, brancher le package `intl` (NumberFormat).
                '${order.totalPrice.toStringAsFixed(0)} MAD',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.primary(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: BorderSide(
              color: AppColors.secondary(context).withValues(alpha: 0.3),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          child: Text(
            'Voir détails',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText(context),
            ),
          ),
        ),
      ],
    );
  }
}