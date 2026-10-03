import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Cart/Widgets/CartItemWidget.dart';
import 'package:connectia/Features/Cart/data/Cubits/CartCubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class Cartview extends StatefulWidget {
  const Cartview({super.key});

  @override
  State<Cartview> createState() => _CartviewState();
}

class _CartviewState extends State<Cartview> {
  @override
  void initState() {
    super.initState();
    context.read<CartCubit>().fetchCart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBg(context),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state is CartLoading) return _buildShimmer();
          if (state is CartError) return _buildError(state.message);
          if (state is CartLoaded) {
            if (state.items.isEmpty) return _buildEmpty();
            return _buildCartList(state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCartList(CartLoaded state) {
    return Column(
      children: [
        SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Cartitemwidget(item: item),
              );
            },
          ),
        ),
        // ── Total summary ──
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sous-total (${state.items.length} articles)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.secondary(context),
                          ),
                        ),
                        if (state.totalSaved > 0)
                          Text(
                            'Économies: -${state.totalSaved.toStringAsFixed(0)} MAD',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.successColor(context),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      '${state.subtotal.toStringAsFixed(0)} MAD',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryText(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/checkout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary(context),
                      foregroundColor: AppColors.onPrimary(context),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Passer la commande',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 72,
            color: AppColors.secondary(context).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Votre panier est vide',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.primaryText(context),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des produits pour commencer vos achats.',
            style: TextStyle(color: AppColors.secondary(context), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.softBg(context),
      highlightColor: AppColors.surface(context),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            height: 200,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: AppColors.secondary(context),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondary(context)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<CartCubit>().fetchCart(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
