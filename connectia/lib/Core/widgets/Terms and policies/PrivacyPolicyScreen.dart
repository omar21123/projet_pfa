import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          'Politique de confidentialité',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary(context),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dernière mise à jour : 14 juillet 2026',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.secondary(context),
                ),
              ),
              const SizedBox(height: 20),
              _Section(
                title: '1. Données collectées',
                body:
                    'Nous collectons les informations que vous fournissez lors de la création de votre compte : nom, prénom, adresse e-mail, mot de passe, numéro de téléphone (facultatif), date de naissance (facultative) et genre (facultatif).',
              ),
              _Section(
                title: '2. Utilisation des données',
                body:
                    'Vos données sont utilisées pour créer et gérer votre compte, faciliter les transactions entre utilisateurs, améliorer nos services et vous contacter en cas de besoin concernant votre compte.',
              ),
              _Section(
                title: '3. Partage des données',
                body:
                    'Connectia ne vend ni ne loue vos données personnelles à des tiers. Certaines informations (nom, photo de profil) peuvent être visibles par d\'autres utilisateurs dans le cadre normal de l\'utilisation de l\'application.',
              ),
              _Section(
                title: '4. Sécurité des données',
                body:
                    'Nous mettons en œuvre des mesures techniques et organisationnelles raisonnables pour protéger vos données contre tout accès non autorisé, perte ou altération.',
              ),
              _Section(
                title: '5. Conservation des données',
                body:
                    'Vos données sont conservées tant que votre compte est actif. Vous pouvez demander la suppression de votre compte et de vos données à tout moment via les paramètres de l\'application.',
              ),
              _Section(
                title: '6. Vos droits',
                body:
                    'Vous disposez d\'un droit d\'accès, de rectification et de suppression de vos données personnelles. Vous pouvez exercer ces droits directement depuis votre profil ou en nous contactant.',
              ),
              _Section(
                title: '7. Cookies et technologies similaires',
                body:
                    'L\'application peut utiliser des technologies de stockage local pour améliorer votre expérience, mémoriser vos préférences et assurer le bon fonctionnement du service.',
              ),
              _Section(
                title: '8. Modification de la politique',
                body:
                    'Cette politique de confidentialité peut être mise à jour périodiquement. Toute modification importante vous sera communiquée via l\'application.',
              ),
              _Section(
                title: '9. Contact',
                body:
                    'Pour toute question concernant cette politique de confidentialité ou vos données personnelles, contactez-nous via la section support de l\'application.',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.secondary(context),
            ),
          ),
        ],
      ),
    );
  }
}