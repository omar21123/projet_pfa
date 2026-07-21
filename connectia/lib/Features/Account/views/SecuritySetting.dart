import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Account/Widgets/Personal%20Information/VerifiableInfoTile.dart';
import 'package:connectia/Features/Account/Widgets/Security/PasswordSettingsCard.dart';
import 'package:connectia/Features/Account/Widgets/Security/SecurityAppBar.dart';
import 'package:connectia/Features/Account/Widgets/Security/SocialAccountRow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class Securitysetting extends StatelessWidget {
  final _currentPadding = const EdgeInsets.symmetric(
    vertical: 10,
    horizontal: 10,
  );
  final _horizontalPadding = const EdgeInsets.symmetric(horizontal: 16);
  const Securitysetting({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBg(context),
      body: CustomScrollView(
        slivers: [
          Securityappbar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: _currentPadding,
              child: PasswordSettingsCard(
                hasPassword: false,
                lastModifiedLabel: 'il y a 3 mois',
                onChangePassword: () {
                  /* navigate to change flow */
                },
                onCreatePassword: () {}, // unused in this branch
              ),
            ),
          ),
          _sectionTitle(context, 'Vérification'),
          SliverToBoxAdapter(
            child: Padding(
              padding: _horizontalPadding,
              child: VerifiableInfoTile(
                title: 'Email',
                value: 'j.durand@connectiaewdfxcwedsa.fr',
                icon: Icons.email_outlined,
                iconColor: AppColors.successColor(context),
                iconBackgroundColor: AppColors.successColorBg(context),
                itemBackgroundColor: AppColors.softBg(context),
                isVerified: false,
                onVerifyTap: () {},
              ),
            ),
          ),
          _gap(10),
          SliverToBoxAdapter(
            child: Padding(
              padding: _horizontalPadding,
              child: VerifiableInfoTile(
                title: 'Téléphone',
                value: '+33 6 12 34 56 78',
                icon: Icons.phone_outlined,
                iconColor: AppColors.wishlist(context),
                iconBackgroundColor: AppColors.wishlistBg(context),
                itemBackgroundColor: AppColors.softBg(context),
                isVerified: true,
                onVerifyTap: () {},
              ),
            ),
          ),
          _gap(10),
          _sectionTitle(context, 'Comptes connectés'),
          SliverToBoxAdapter(
            child: Padding(
              padding: _currentPadding,
              child: SocialAccountsCard(
                rows: [
                  SocialAccountRow(
                    icon: SvgPicture.asset('assets/images/google.svg'),
                    isConnected: true,
                    onConnect: () {},
                    onDisconnect: () {},
                    title: 'Google',
                    enabled: true,
                    username: 'Jean-Sébastien Martin',
                  ),
                  SocialAccountRow(
                    icon: SvgPicture.asset('assets/images/apple.svg'),
                    isConnected: false,
                    onConnect: () {},
                    onDisconnect: () {},
                    title: 'Apple',
                    enabled: false,
                    username: 'Non connecté',
                  ),
                  SocialAccountRow(
                    icon: SvgPicture.asset('assets/images/facebook.svg'),
                    isConnected: true,
                    onConnect: () {},
                    onDisconnect: () {},
                    title: 'Facebook',
                    enabled: false,
                    username: 'js.martin',
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _gap(double height) {
    return SliverToBoxAdapter(child: SizedBox(height: height));
  }

  SliverToBoxAdapter _sectionTitle(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: 10),
        child: Text(
          title,
          style: TextStyle(
            color: AppColors.primary(context),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
