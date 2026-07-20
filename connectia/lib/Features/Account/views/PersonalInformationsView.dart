import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/widgets/Buttons/CustomActionButton.dart';
import 'package:connectia/Features/Account/Widgets/Personal%20Information/AccountAccessInfo.dart';
import 'package:connectia/Features/Account/Widgets/Personal%20Information/EditableAvatar.dart';
import 'package:connectia/Features/Account/Widgets/Personal%20Information/IdentitySection.dart';
import 'package:connectia/Features/Account/Widgets/Personal%20Information/LoyaltyPointsCard.dart';
import 'package:connectia/Features/Account/Widgets/Personal%20Information/NotificationToggleTile.dart';
import 'package:connectia/Features/Account/Widgets/Personal%20Information/VerifiableInfoTile.dart';
import 'package:connectia/Features/Account/data/Models/IdentityData.dart';
import 'package:flutter/material.dart';

class PersonalinformationsView extends StatelessWidget {
  final _horizontalPadding = const EdgeInsets.symmetric(horizontal: 16);

  const PersonalinformationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBg(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryText(context)),
        title: Text(
          "Informations personnelles",
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [_buildSaveButton(context)],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Avatar ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: EditableAvatar(
                imagePath:
                    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTNIt52qUljGdJXFymRUK_ZPTSKAyeB1SJzA3N1ORpIwg&s=10',
                fullName: 'Mohammed Bourass',
                onImageChanged: (file) {},
              ),
            ),
          ),
          _gap(24),

          // ── Identité ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: _horizontalPadding,
              child: IdentitySection(
                initialData: IdentityData(
                  firstName: 'Mohammed',
                  lastName: 'Bourass',
                  birthDate: DateTime.now(),
                  gender: Gender.homme,
                ),
                onChanged: (newValue) {},
              ),
            ),
          ),
          _gap(28),

          // ── Contact & Vérification ─────────────────────────
          _sectionTitle(context, 'Contact & Vérification'),
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
          _gap(28),

          // ── Détails du compte ───────────────────────────────
          _sectionTitle(context, 'Détails du compte'),
          SliverToBoxAdapter(
            child: Padding(
              padding: _horizontalPadding,
              child: AccountAccessInfo(
                publicId: 'JB-DRND-88X',
                hasPassword: true,
                onConnectionMethodTap: () {
                  // navigue vers la page Sécurité
                },
              ),
            ),
          ),
          _gap(28),

          // ── Préférences & Fidélité ──────────────────────────
          _sectionTitle(context, 'Préférences & Fidélité'),
          SliverToBoxAdapter(
            child: Padding(
              padding: _horizontalPadding,
              child: LoyaltyPointsCard(points: 140),
            ),
          ),
          _gap(10),
          SliverToBoxAdapter(
            child: Padding(
              padding: _horizontalPadding,
              child: NotificationToggleTile(
                title: 'Emails marketing',
                subtitle: 'Actualités et offres',
                icon: Icons.mail_outline,
                isActive: true,
                onChanged: (value) {},
              ),
            ),
          ),
          _gap(32),

          // ── Zone de danger ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: _horizontalPadding,
              child: CustomActionButton(
                icon: Icons.delete_outline,
                text: 'Supprimer mon compte',
                color: AppColors.logout(context),
                backgroundColor: AppColors.logoutBg(context),
                onClick: () {},
              ),
            ),
          ),
          _gap(24),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Center(
        child: TextButton.icon(
          onPressed: () {},
          style: TextButton.styleFrom(
            backgroundColor: AppColors.accent20(context),
            foregroundColor: AppColors.primary(context),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.check, size: 18),
          label: const Text(
            '',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _sectionTitle(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: 10),
        child: Text(
          title,
          style: TextStyle(
            color: AppColors.primary(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _gap(double height) {
    return SliverToBoxAdapter(child: SizedBox(height: height));
  }
}
