import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Cart/Widgets/QuantityStepperCard.dart';
import 'package:connectia/Features/Cart/data/Cubits/CartCubit.dart';
import 'package:connectia/Features/Cart/data/Models/CartItemResponseModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class Cartitemwidget extends StatelessWidget {
  final CartItemResponseModel item;

  const Cartitemwidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent30(context), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image + Info row ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  item.imagePath,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 90,
                    height: 90,
                    color: AppColors.accent20(context),
                    child: Icon(Icons.image_not_supported_outlined,
                        color: AppColors.secondary(context)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      item.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.primaryText(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Brand + Model
                    Text(
                      '${item.brandName} · ${item.modelName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.secondary(context),
                        fontSize: 12,
                      ),
                    ),
                    // SKU
                    if (item.sku != null && item.sku!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'SKU: ${item.sku}',
                        style: TextStyle(
                          color: AppColors.secondary(context),
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Price
                    Row(
                      children: [
                        if (item.hasPromotion && item.promotion != null) ...[
                          Text(
                            '${item.unitPrice.toStringAsFixed(0)} MAD',
                            style: TextStyle(
                              color: AppColors.secondary(context),
                              fontSize: 13,
                              decoration: TextDecoration.lineThrough,
                              decorationColor:
                                  AppColors.secondary(context).withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.logout(context).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.promotion!.discountFormatted,
                              style: TextStyle(
                                color: AppColors.logout(context),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          '${(item.totalPrice / item.quantity).toStringAsFixed(0)} MAD',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.primary(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Combination details (config options) ──
          if (item.combinationDetails.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.softBg(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: item.combinationDetails.map((detail) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            AppColors.secondary(context).withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${detail.configName}: ',
                          style: TextStyle(
                            color: AppColors.secondary(context),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          detail.optionLabel,
                          style: TextStyle(
                            color: AppColors.primaryText(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // ── Quantity + Total ──
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 140,
                  child: QuantityStepperCard(
                    initialValue: item.quantity,
                    max: item.stock,
                    onChanged: (qty) {
                      context.read<CartCubit>().updateQuantity(
                            item.cartItemID,
                            qty,
                          );
                    },
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (item.hasPromotion && item.savedAmount > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          'Économisez ${item.savedAmount.toStringAsFixed(0)} MAD',
                          style: TextStyle(
                            color: AppColors.successColor(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Text(
                      '${item.totalPrice.toStringAsFixed(0)} MAD',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: AppColors.primaryText(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Delete button ──
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {
                  context.read<CartCubit>().removeFromCart(
                        item.productId,
                        item.combinationId,
                      );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 16, color: AppColors.logout(context)),
                      const SizedBox(width: 4),
                      Text(
                        'Retirer du panier',
                        style: TextStyle(
                          color: AppColors.logout(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
