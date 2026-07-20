import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/Navigations/CustomNavigator.dart';
import 'package:connectia/Core/storage/AppPreferencesService.dart';
import 'package:connectia/Features/Account/data/Dark%20Mode%20Cubit/dark_mode_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:connectia/Core/DI/locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await initLocator();
  //locator<AppPreferencesService>().clearAll();
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
           bool isDarkMode = PlatformDispatcher.instance.platformBrightness == Brightness.dark;

            return DarkModeCubit()..initiale(isDarkMode);
          },
        ),
      ],
      child: const ConnectiaApp(),
    ),
  );
}

class ConnectiaApp extends StatelessWidget {
  const ConnectiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DarkModeCubit, DarkModeState>(
      builder: (context, state) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: CustomNavigator.router,
          title: 'Connectia',
          themeMode: state is DarkModeActive ? ThemeMode.dark : ThemeMode.light,
          // ── Light theme ─────────────────────────────────────────
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppColors.softBackground,
            primaryColor: AppColors.primaryBrand,
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBrand,
              secondary: AppColors.secondaryText,
              surface: AppColors.defaultBase,
            ),
            textTheme: TextTheme(
              bodyMedium: TextStyle(color: AppColors.primaryBrand),
            ),
          ),

          // ── Dark theme ──────────────────────────────────────────
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.defaultBaseDark,
            primaryColor: AppColors.primaryBrandDark,
            colorScheme: ColorScheme.dark(
              primary: AppColors.primaryBrandDark,
              secondary: AppColors.secondaryTextDark,
              surface: AppColors.softBackgroundDark,
            ),
            textTheme: TextTheme(
              bodyMedium: TextStyle(color: AppColors.secondaryTextDark),
            ),
          ),
        );
      },
    );
  }
}
