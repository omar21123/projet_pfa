import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

/// Page standard "À propos" : logo, version, liens légaux, copyright.
class AboutPage extends StatelessWidget {
  final String appName;
  final String appVersion;
  final String? appLogoAssetPath;
  final VoidCallback? onTermsTap;
  final VoidCallback? onPrivacyPolicyTap;
  final VoidCallback? onLegalNoticeTap;
  final VoidCallback? onRateAppTap;

  const AboutPage({
    super.key,
    this.appName = 'connectia',
    this.appVersion = 'Version 1.0.0',
    this.appLogoAssetPath,
    this.onTermsTap,
    this.onPrivacyPolicyTap,
    this.onLegalNoticeTap,
    this.onRateAppTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBg(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryText(context)),
        title: Text(
          'À propos',
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _buildLogoHeader(context),
          const SizedBox(height: 28),
          _buildLegalCard(context),
          const SizedBox(height: 20),
          if (onRateAppTap != null) ...[
            _buildRateAppButton(context),
            const SizedBox(height: 20),
          ],
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildLogoHeader(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.accent20(context),
              borderRadius: BorderRadius.circular(24),
            ),
            child: appLogoAssetPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(appLogoAssetPath!, fit: BoxFit.cover),
                  )
                : Icon(Icons.storefront, color: AppColors.primary(context), size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            appName,
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            appVersion,
            style: TextStyle(
              color: AppColors.secondary(context),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _AboutRow(
            label: "Conditions d'utilisation",
            onTap: onTermsTap,
          ),
          _divider(context),
          _AboutRow(
            label: 'Politique de confidentialité',
            onTap: onPrivacyPolicyTap,
          ),
          _divider(context),
          _AboutRow(
            label: 'Mentions légales',
            onTap: onLegalNoticeTap,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: AppColors.secondary(context).withValues(alpha: 0.15),
    );
  }

  Widget _buildRateAppButton(BuildContext context) {
    return InkWell(
      onTap: onRateAppTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.accent20(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border, color: AppColors.primary(context), size: 18),
            const SizedBox(width: 8),
            Text(
              "Noter l'application",
              style: TextStyle(
                color: AppColors.primary(context),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final year = DateTime.now().year;
    return Column(
      children: [
        Text(
          'Développé par eByte Software',
          style: TextStyle(color: AppColors.secondary(context), fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          '© $year $appName. Tous droits réservés.',
          style: TextStyle(color: AppColors.secondary(context), fontSize: 12),
        ),
      ],
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLast;

  const _AboutRow({
    required this.label,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isLast ? Radius.zero : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.primaryText(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.secondary(context), size: 20),
          ],
        ),
      ),
    );
  }
}