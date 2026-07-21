import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Account/Widgets/Pref/CurrencySection.dart';
import 'package:connectia/Features/Account/Widgets/Pref/LanguageSection.dart';
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background(context),
            elevation: 0,
            expandedHeight: 130,
            iconTheme: IconThemeData(color: AppColors.primaryText(context)),
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final expandRatio =
                    ((constraints.maxHeight - kToolbarHeight) /
                            (130 - kToolbarHeight))
                        .clamp(0.0, 1.0);

                return FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  centerTitle: false,
                  title: Text(
                    'Préférences',
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 18 + (4 * expandRatio),
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.background(context),
                          AppColors.accent20(context),
                        ],
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 24, top: 10),
                        child: Opacity(
                          opacity: expandRatio,
                          child: Icon(
                            Icons.tune_rounded,
                            size: 64,
                            color: AppColors.primary(
                              context,
                            ).withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
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
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
          ),
        ],
      ),
    );
  }
}
