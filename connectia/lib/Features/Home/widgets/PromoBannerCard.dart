import 'package:flutter/material.dart';

/// Bannière promo pleine largeur (image de fond + titre + CTA), inspirée
/// du hero banner "Level Up Your Game".
class PromoBannerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String primaryActionLabel;
  final VoidCallback onPrimaryActionTap;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryActionTap;

  const PromoBannerCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.primaryActionLabel,
    required this.onPrimaryActionTap,
    this.secondaryActionLabel,
    this.onSecondaryActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.0), Colors.black.withValues(alpha: 0.65)],
          ),
        ),
        padding: const EdgeInsets.all(18),
        alignment: Alignment.bottomLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                ElevatedButton(
                  onPressed: onPrimaryActionTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(primaryActionLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                if (secondaryActionLabel != null) ...[
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: onSecondaryActionTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(secondaryActionLabel!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}