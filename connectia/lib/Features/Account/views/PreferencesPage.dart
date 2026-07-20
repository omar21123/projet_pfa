import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Account/Widgets/Pref/CurrencySection.dart';
import 'package:connectia/Features/Account/Widgets/Pref/LanguageSection.dart';
import 'package:connectia/Features/Account/Widgets/Pref/SectionCard.dart';
import 'package:connectia/Features/Account/Widgets/Pref/ThemeSection.dart';
import 'package:connectia/Features/Account/data/Dark%20Mode%20Cubit/dark_mode_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Page Préférences : Langue / Thème / Devise, chacune dans son propre
/// widget à l'intérieur d'un CustomScrollView.
class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.softBg(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.primaryText(context)),
        title: Text(
          'Préférences',
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: LanguageSection()),
          SliverToBoxAdapter(
            child: ThemeSection(
              isDark: isDark,
              onDarkMode: () async {
                await context.read<DarkModeCubit>().setDarkMode();
              },
              onWhiteMode: () async {
                await context.read<DarkModeCubit>().setLightMode();
              },
            ),
          ),
          SliverToBoxAdapter(child: CurrencySection()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
