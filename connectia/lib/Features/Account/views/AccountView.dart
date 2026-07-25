import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/Navigations/CustomNavigator.dart';
import 'package:connectia/Core/widgets/Buttons/CustomNavigationButton.dart';
import 'package:connectia/Features/Account/Widgets/CustomerProfileSliver.dart';
import 'package:connectia/Features/Account/Widgets/MenuTileCard.dart';
import 'package:flutter/material.dart';
import 'package:pro_dialog/pro_dialog.dart';

class Accountview extends StatelessWidget {
  const Accountview({super.key});
  final _currentPadding = const EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
  );
  final _itemsPAdding = const EdgeInsets.fromLTRB(16, 5, 16, 5);
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Text(
            'Mon compte',
            style: TextStyle(color: AppColors.primaryText(context)),
          ),
        ),
        CustomerProfileSliver(
          padding: _currentPadding,
          fullName: 'Jean-Sébastien Martin',
          email: 'js.martin@connectia.fr',
          avatarUrl: 'https://...',
          achatsCount: 12,
          favorisCount: 5,
          wishlistItems: 10,
          onEditTap: onPersonalInfoTap,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: _currentPadding,
            child: Text(
              'MON ACTIVITE',

              style: TextStyle(color: AppColors.primaryText(context)),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: _itemsPAdding,
            child: MenuTileCard(
              title: 'Liste de souhaits',
              subtitle: 'Articles enregistrés',
              icon: Icons.favorite_border,
              iconColor: AppColors.wishlist(context),
              iconBackgroundColor: AppColors.wishlistBg(context),
              onTap: onWishlistTap,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: _itemsPAdding,
            child: MenuTileCard(
              title: 'Produits aimés',
              subtitle: 'Vos coups de cœur',
              icon: Icons.thumb_up_outlined,
              iconColor: AppColors.likedProducts(context),
              iconBackgroundColor: AppColors.likedProductsBg(context),
              onTap: onLikedProductsTap,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: _itemsPAdding,
            child: MenuTileCard(
              title: 'Historique des achats',
              subtitle: 'Vos commandes passées',
              icon: Icons.history,
              iconColor: AppColors.history(context),
              iconBackgroundColor: AppColors.historyBg(context),
              onTap: onOrderHistoryTap,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: _currentPadding,
            child: Text(
              'COMPTE',
              style: TextStyle(color: AppColors.primaryText(context)),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: _itemsPAdding,
            child: MenuTileCard(
              title: 'Informations personnelles',
              subtitle: 'Nom, e-mail, téléphone',
              icon: Icons.person_outline,
              iconColor: AppColors.neutral(context),
              iconBackgroundColor: AppColors.neutralBg(context),
              onTap: onPersonalInfoTap,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: _itemsPAdding,
            child: MenuTileCard(
              title: 'Gestion des adresses',
              subtitle: 'Adresses de livraison',
              icon: Icons.push_pin_outlined,
              iconColor: AppColors.neutral(context),
              iconBackgroundColor: AppColors.neutralBg(context),
              onTap: onAddressesTap,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: _itemsPAdding,
            child: MenuTileCard(
              title: 'Sécurité',
              subtitle: 'Mot de passe, connexion',
              icon: Icons.lock_outline,
              iconColor: AppColors.security(context),
              iconBackgroundColor: AppColors.securityBg(context),
              onTap: onSecurityTap,
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: _currentPadding,
            child: Text(
              'PREFERENCES',
              style: TextStyle(color: AppColors.primaryText(context)),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: _itemsPAdding,
            child: MenuTileCard(
              title: 'Préférences',
              subtitle: 'Langue, thème, devise',
              icon: Icons.tune,
              // Même style neutre que "Informations personnelles" / "Historique"
              iconColor: AppColors.neutral(context),
              iconBackgroundColor: AppColors.neutralBg(context),
              onTap: onPreferencesTap,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: _itemsPAdding,
            child: MenuTileCard(
              title: 'Notifications',
              subtitle: 'Gérer vos alertes',
              icon: Icons.notifications_none,
              iconColor: AppColors.notifications(context),
              iconBackgroundColor: AppColors.notificationsBg(context),
              onTap: onNotificationsTap,
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: _currentPadding,
            child: Text(
              'ASSISTANCE',
              style: TextStyle(color: AppColors.primaryText(context)),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: _itemsPAdding,
            child: MenuTileCard(
              title: "Centre d'aide",
              subtitle: 'FAQ et support',
              icon: Icons.help_center_outlined,
              iconColor: AppColors.neutral(context),
              iconBackgroundColor: AppColors.neutralBg(context),
              onTap: onHelpCenterTap,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: _itemsPAdding,
            child: MenuTileCard(
              title: 'À propos',
              subtitle: 'Version, conditions, confidentialité',
              icon: Icons.info_outline,
              iconColor: AppColors.neutral(context),
              iconBackgroundColor: AppColors.neutralBg(context),
              onTap: onAboutTap,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
            child: Customnavigationbutton(
              backgroundColor: AppColors.logoutBg(context),
              onPressed: () {
                showProDialog(
                  context,
                  type: DialogType.question,
                  title: 'Se déconnecter',
                  description:
                      'Voulez-vous vraiment vous déconnecter de votre compte ?',
                  buttons: [
                    DialogButton(
                      text: 'Annuler',
                      onPressed: () => Navigator.pop(context),
                    ),
                    DialogButton(
                      text: 'Se déconnecter',
                      isPrimary: true,
                      onPressed: () {},
                    ),
                  ],
                );
              },
              text: 'Se déconnecter',
              textColor: AppColors.logout(context),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(10, 50, 20, 200),
            child: Center(child: Text('Connectia · v1.0.0')),
          ),
        ),
      ],
    );
  }

  void onWishlistTap() async {
    await CustomNavigator.navigateWishlistsPage();
  }

  void onLikedProductsTap() async {
    await CustomNavigator.navigateProductslovedPage();
  }

  void onOrderHistoryTap() async {
    await CustomNavigator.navigateOrdershistoryPage();
  }

  void onPersonalInfoTap() async {
    await CustomNavigator.navigateToSettingPersonalinformationsView();
  }

  void onAddressesTap() async {
    await CustomNavigator.navigateToSettingAddressesview();
  }

  void onSecurityTap() async {
    await CustomNavigator.navigateToSecuritysetting();
  }

  void onPreferencesTap() async {
    await CustomNavigator.navigateToSettingPReferences();
  }

  void onNotificationsTap() {}

  void onHelpCenterTap() async {
    await CustomNavigator.navigateToSettingFAQHelp();
  }

  void onAboutTap() async {
    await CustomNavigator.navigateToSettingAbout();
  }
}
