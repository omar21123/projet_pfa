import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          'Conditions d\'utilisation',
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
                title: '1. Acceptation des conditions',
                body:
                    'En créant un compte sur Connectia, vous acceptez d\'être lié par les présentes conditions d\'utilisation. Si vous n\'acceptez pas ces conditions, veuillez ne pas utiliser l\'application.',
              ),
              _Section(
                title: '2. Description du service',
                body:
                    'Connectia est une plateforme permettant aux utilisateurs d\'acheter et de vendre des biens ou services entre particuliers. Nous agissons uniquement en tant qu\'intermédiaire technique et ne sommes pas partie aux transactions effectuées entre utilisateurs.',
              ),
              _Section(
                title: '3. Compte utilisateur',
                body:
                    'Vous êtes responsable de la confidentialité de vos identifiants de connexion et de toutes les activités effectuées depuis votre compte. Vous devez nous informer immédiatement de toute utilisation non autorisée de votre compte.',
              ),
              _Section(
                title: '4. Comportement des utilisateurs',
                body:
                    'Vous vous engagez à ne pas publier de contenu illégal, trompeur, offensant ou portant atteinte aux droits d\'autrui. Connectia se réserve le droit de suspendre ou de supprimer tout compte ne respectant pas ces règles.',
              ),
              _Section(
                title: '5. Transactions entre utilisateurs',
                body:
                    'Connectia ne garantit pas la qualité, la sécurité ou la légalité des articles ou services proposés par les utilisateurs. Toute transaction est réalisée sous la seule responsabilité des parties concernées.',
              ),
              _Section(
                title: '6. Propriété intellectuelle',
                body:
                    'Tous les éléments graphiques, textuels et techniques de l\'application sont la propriété de Connectia et ne peuvent être reproduits sans autorisation préalable.',
              ),
              _Section(
                title: '7. Limitation de responsabilité',
                body:
                    'Connectia ne pourra être tenue responsable des dommages directs ou indirects résultant de l\'utilisation de l\'application ou de transactions entre utilisateurs.',
              ),
              _Section(
                title: '8. Modification des conditions',
                body:
                    'Nous nous réservons le droit de modifier ces conditions à tout moment. Les utilisateurs seront informés de tout changement important via l\'application.',
              ),
              _Section(
                title: '9. Résiliation',
                body:
                    'Connectia peut suspendre ou résilier votre accès au service à tout moment en cas de non-respect des présentes conditions.',
              ),
              _Section(
                title: '10. Contact',
                body:
                    'Pour toute question relative à ces conditions, vous pouvez nous contacter via la section support de l\'application.',
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