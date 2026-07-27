import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Cart/data/Models/OptionChoosesConfig.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Résumé "CONFIGURATION" en lecture seule : liste de pills empilées,
/// une par option choisie, avec une icône adaptée au type de config.
class ProductConfigsPanel extends StatelessWidget {
  final List<OptionChoosesConfig> options;
  final EdgeInsets padding;

  const ProductConfigsPanel({
    super.key,
    required this.options,
    this.padding = EdgeInsets.zero,
  });

  IconData _iconFor(String configName) {
    final name = configName.toLowerCase();
    if (name.contains('couleur') || name.contains('color')) {
      return Icons.palette_outlined;
    }
    if (name.contains('taille') || name.contains('size')) {
      return Icons.straighten_rounded;
    }
    if (name.contains('kit') ||
        name.contains('objectif') ||
        name.contains('lens')) {
      return Icons.camera_alt_outlined;
    }
    if (name.contains('garantie') || name.contains('warranty')) {
      return Icons.shield_outlined;
    }
    if (name.contains('matière') || name.contains('material')) {
      return Icons.texture_rounded;
    }
    if (name.contains('stockage') || name.contains('storage')) {
      return Icons.sd_storage_outlined;
    }
    return Icons.tune_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'CONFIGURATION',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.secondary(context),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(options.length * 2 - 1, (i) {
            if (i.isOdd) return const SizedBox(height: 10);

            final option = options[i ~/ 2];
            return _ConfigChip(
              icon: _iconFor(option.configName),
              configName: option.configName,
              optionName: option.optionName,
            );
          }),
        ],
      ),
    );
  }
}

class _ConfigChip extends StatelessWidget {
  final IconData icon;
  final String configName;
  final String optionName;

  const _ConfigChip({
    required this.icon,
    required this.configName,
    required this.optionName,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.softBg(context),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primaryText(context)),
            const SizedBox(width: 10),
            Text.rich(
              TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText(context),
                ),
                children: [
                  TextSpan(text: '$configName: '),
                  TextSpan(
                    text: optionName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
