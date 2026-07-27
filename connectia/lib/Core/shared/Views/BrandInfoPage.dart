import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/shared/Models/BrandModel.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Page "Infos marque" : SliverAppBar avec logo en fond (flou + dégradé),
/// nom + badge vérifié, pays, site web, description, et explication de
/// ce que signifie la vérification.
class BrandInfoPage extends StatelessWidget {
  final BrandModel brand;

  const BrandInfoPage({super.key, required this.brand});

  Future<void> _openWebsite() async {
    final uri = Uri.tryParse(brand.website);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBg(context),
      body: CustomScrollView(
        slivers: [
          _BrandSliverAppBar(brand: brand),
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 640;

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? constraints.maxWidth * 0.15 : 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        icon: Icons.public_rounded,
                        label: 'Pays',
                        value: brand.countryName,
                      ),
                      const SizedBox(height: 14),
                      _InfoRow(
                        icon: Icons.link_rounded,
                        label: 'Site web',
                        value: brand.website,
                        onTap: _openWebsite,
                        isLink: true,
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'À PROPOS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppColors.primaryText(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        brand.description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondary(context),
                          height: 1.6,
                        ),
                      ),
                      if (brand.isVerified) ...[
                        const SizedBox(height: 28),
                        const _VerificationNotice(),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// SliverAppBar avec le logo en fond flouté (FlexibleSpaceBar) — se
/// réduit au scroll et affiche le nom de la marque dans la barre
/// collapsed comme un titre classique.
class _BrandSliverAppBar extends StatelessWidget {
  final BrandModel brand;

  const _BrandSliverAppBar({required this.brand});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 240,
      backgroundColor: AppColors.background(context),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => context.pop(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16, right: 16),
        title: Text(
          brand.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Logo étiré en fond
            Image.network(
              brand.logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: AppColors.accent20(context)),
            ),
            // Flou pour que le texte / bouton retour restent lisibles
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(color: Colors.black.withValues(alpha: 0.1)),
            ),
            // Dégradé sombre en bas pour la lisibilité du titre
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
            // Logo réel, net, au centre (au-dessus du flou de fond)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: ClipOval(
                  child: Container(
                    width: 92,
                    height: 92,
                    color: Colors.white,
                    padding: const EdgeInsets.all(4),
                    child: ClipOval(
                      child: Image.network(
                        brand.logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.storefront_rounded,
                          size: 36,
                          color: AppColors.primary(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (brand.isVerified)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: AppColors.successColor(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Vérifié',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.successColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.25),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 17, color: Colors.white),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool isLink;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accent20(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary(context)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isLink
                          ? AppColors.primary(context)
                          : AppColors.primaryText(context),
                    ),
                  ),
                ],
              ),
            ),
            if (isLink)
              Icon(
                Icons.arrow_outward_rounded,
                size: 16,
                color: AppColors.secondary(context),
              ),
          ],
        ),
      ),
    );
  }
}

class _VerificationNotice extends StatelessWidget {
  const _VerificationNotice();

  @override
  Widget build(BuildContext context) {
    final successColor = AppColors.successColor(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successColorBg(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_rounded, size: 20, color: successColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Marque vérifiée',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: successColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'La vérification signifie que cette marque a été '
                  'contrôlée et validée par notre équipe. Vous pouvez '
                  'acheter en toute confiance.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: successColor.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
