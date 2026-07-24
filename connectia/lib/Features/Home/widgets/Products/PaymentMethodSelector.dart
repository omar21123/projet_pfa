import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum PaymentMethod { cod, online }

/// Sélecteur "Paiement" (À la livraison / Carte Bancaire), carte
/// sélectionnée avec bordure teal épaisse, non-sélectionnée en surface plate.
class PaymentMethodSelector extends StatefulWidget {
  final ValueChanged<PaymentMethod> onChanged;

  const PaymentMethodSelector({super.key, required this.onChanged});

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  PaymentMethod _value = PaymentMethod.cod;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PAIEMENT',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AppColors.primaryText(context),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PaymentCard(
                icon: Icons.payments_outlined,
                label: 'À la livraison',
                isSelected: _value == PaymentMethod.cod,
                onTap: () {
                  setState(() {
                    _value = PaymentMethod.cod;
                  });

                  widget.onChanged(PaymentMethod.cod);
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _PaymentCard(
                icon: Icons.credit_card_rounded,
                label: 'Carte Bancaire',
                isSelected: _value == PaymentMethod.online,
                onTap: () {
                  setState(() {
                    _value = PaymentMethod.online;
                  });

                  widget.onChanged(PaymentMethod.online);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primary(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: AppColors.background(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : AppColors.secondary(context).withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: AppColors.primaryText(context)),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
