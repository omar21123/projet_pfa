import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sélecteur de quantité façon pill pleine largeur (- / valeur / +), min = 0.
/// Affiche un message rouge au-dessus dès que la quantité atteint 0.
class QuantitySelector extends StatefulWidget {
  final int initialValue;
  final int min;
  final int? max;
  final ValueChanged<int> onChanged;
  final String zeroWarningMessage;

  const QuantitySelector({
    super.key,
    this.initialValue = 1,
    this.min = 0,
    this.max,
    required this.onChanged,
    this.zeroWarningMessage = 'Ce produit sera retiré de votre panier.',
  });

  @override
  State<QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  late int _quantity = widget.initialValue;

  bool get _isAtZero => _quantity <= widget.min;
  bool get _isAtMax => widget.max != null && _quantity >= widget.max!;

  void _update(int newValue) {
    final clamped = newValue.clamp(widget.min, widget.max ?? newValue);
    if (clamped == _quantity) return;
    setState(() => _quantity = clamped);
    widget.onChanged(_quantity);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent30(context), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUANTITÉ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.primaryText(context),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: _isAtZero
                ? Padding(
                    key: const ValueKey('warning'),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      widget.zeroWarningMessage,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade600,
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.softBg(context),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _QuantityButton(
                  icon: Icons.remove_rounded,
                  onTap: _isAtZero ? null : () => _update(_quantity - 1),
                ),
                Text(
                  '$_quantity',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText(context),
                  ),
                ),
                _QuantityButton(
                  icon: Icons.add_rounded,
                  onTap: _isAtMax ? null : () => _update(_quantity + 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return Material(
      color: AppColors.background(context),
      borderRadius: BorderRadius.circular(14),
      elevation: disabled ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 18,
            color: disabled
                ? AppColors.secondary(context).withValues(alpha: 0.4)
                : AppColors.primaryText(context),
          ),
        ),
      ),
    );
  }
}
