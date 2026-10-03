import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/functions/Frenchdateformatter.dart';
import 'package:connectia/Features/Account/Widgets/Orders%20History/OrderStatusBadge.dart';
import 'package:connectia/Features/Account/data/Models/OrderListItem.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderCard extends StatelessWidget {
  final OrderListItem order;
  final VoidCallback onTap;

  const OrderCard({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
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
            // ── Header: order number + status ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.orderNumber,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.primaryText(context),
                    ),
                  ),
                ),
                OrderStatusBadge(statusCode: order.statusCode),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formatFrenchDate(order.orderedAt),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.secondary(context),
              ),
            ),
            const SizedBox(height: 14),

            // ── Info row: items + vendors ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.softBg(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildInfoChip(
                    context,
                    icon: Icons.shopping_bag_outlined,
                    label: '${order.totalItems} article${order.totalItems > 1 ? 's' : ''}',
                  ),
                  const SizedBox(width: 16),
                  _buildInfoChip(
                    context,
                    icon: Icons.storefront_outlined,
                    label: '${order.totalVendors} vendeur${order.totalVendors > 1 ? 's' : ''}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Footer: total + details button ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${order.total.toStringAsFixed(2)} ${order.currency}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: AppColors.primary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(
                      color: AppColors.secondary(context).withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(
                    'Voir détails',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, {required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.secondary(context)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryText(context),
          ),
        ),
      ],
    );
  }
}
