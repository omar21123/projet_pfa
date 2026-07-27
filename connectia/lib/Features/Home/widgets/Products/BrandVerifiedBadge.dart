import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Badge "Marque + Vérifié" façon pill, utilisé sur les pages détail produit
/// / profil boutique. Affiche le logo de la marque (avatar circulaire),
/// scale-down animé au tap + halo pulsé discret autour du check
/// quand [isVerified] est true.
class BrandVerifiedBadge extends StatefulWidget {
  final String label;
  final bool isVerified;
  final String? iconPath; // URL du logo de la marque
  final VoidCallback? onTap;

  const BrandVerifiedBadge({
    super.key,
    required this.label,
    this.isVerified = false,
    this.iconPath,
    this.onTap,
  });

  @override
  State<BrandVerifiedBadge> createState() => _BrandVerifiedBadgeState();
}

class _BrandVerifiedBadgeState extends State<BrandVerifiedBadge>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  late final Animation<double> _pulse = CurvedAnimation(
    parent: _pulseController,
    curve: Curves.easeInOut,
  );

  @override
  void deactivate() {
    // Stoppe le ticker dès que le widget commence à quitter l'arbre
    // (ex: pendant une transition de route) pour éviter tout setState
    // déclenché alors que le context est temporairement inactif.
    _pulseController.stop();
    super.deactivate();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    if (!mounted) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    if (!mounted) return;
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final successColor = AppColors.successColor(context);
    final successBg = AppColors.successColorBg(context);

    return GestureDetector(
      onTap: widget.onTap == null ? null : _handleTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.background(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.accent30(context), width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BrandLogo(iconPath: widget.iconPath),
              const SizedBox(width: 10),
              Text(
                widget.label.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: AppColors.primaryText(context),
                ),
              ),
              if (widget.isVerified) ...[
                const SizedBox(width: 10),
                _VerifiedChip(
                  color: successColor,
                  backgroundColor: successBg,
                  pulse: _pulse,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  final String? iconPath;

  const _BrandLogo({required this.iconPath});

  @override
  Widget build(BuildContext context) {
    const size = 30.0;

    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: AppColors.accent20(context),
        child: iconPath == null
            ? Icon(
                Icons.storefront_rounded,
                size: 17,
                color: AppColors.primary(context),
              )
            : Image.network(
                iconPath!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation(
                        AppColors.primary(context),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.storefront_rounded,
                  size: 17,
                  color: AppColors.primary(context),
                ),
              ),
      ),
    );
  }
}

class _VerifiedChip extends StatelessWidget {
  final Color color;
  final Color backgroundColor;
  final Animation<double> pulse;

  const _VerifiedChip({
    required this.color,
    required this.backgroundColor,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: pulse,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35 * pulse.value),
                      blurRadius: 7 * pulse.value,
                      spreadRadius: 1.8 * pulse.value,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Icon(Icons.verified_rounded, size: 17, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            'Vérifié',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
