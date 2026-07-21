import 'package:connectia/Core/DI/locator.dart';
import 'package:connectia/Core/storage/AppPreferencesService.dart';
import 'package:connectia/Core/widgets/Terms%20and%20policies/PrivacyPolicyScreen.dart';
import 'package:connectia/Core/widgets/Terms%20and%20policies/TermsOfUseScreen.dart';
import 'package:connectia/Features/Account/views/AboutPage.dart';
import 'package:connectia/Features/Account/views/AddressesView.dart';
import 'package:connectia/Features/Account/views/HelpCenterPage.dart';
import 'package:connectia/Features/Account/views/PersonalInformationsView.dart';
import 'package:connectia/Features/Account/views/PreferencesPage.dart';
import 'package:connectia/Features/Forgotpassword/presentation/Views/ForgotPasswordEmailScreen.dart';
import 'package:connectia/Features/Forgotpassword/presentation/Views/ResetPasswordScreen.dart';
import 'package:connectia/Features/Forgotpassword/presentation/Views/VerifyResetCodeScreen.dart';
import 'package:connectia/Features/Login/Login.dart';
import 'package:connectia/Features/Onboarding/Views/IntroductionView.dart';
import 'package:connectia/Features/Register/RegisterScreen.dart';
import 'package:connectia/Features/main/views/mainPage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomNavigator {
  CustomNavigator._(); // prevents instantiation

  // ✅ Global navigator key — lives forever, no context needed
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final prefs = locator<AppPreferencesService>();
      final location = state.matchedLocation;

      const introRoute = '/introduction';
      const authRoutes = {
        '/login',
        '/register',
        '/terms',
        '/privacy',
        '/forgot-password',
        '/forgot-password/verify',
        '/forgot-password/reset',
      };

      if (prefs.isShowOnboarding) {
        return location == introRoute ? null : introRoute;
      }

      if (prefs.isShowLogin && !authRoutes.contains(location)) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const Mainpage()),
      GoRoute(
        path: '/introduction',
        builder: (context, state) => const Introductionview(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const Login()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const Registerscreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsOfUseScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordEmailScreen(),
      ),
      GoRoute(
        path: '/forgot-password/verify',
        builder: (context, state) =>
            VerifyResetCodeScreen(email: state.extra as String),
      ),
      GoRoute(
        path: '/forgot-password/reset',
        builder: (context, state) {
          final args = state.extra as Map<String, String>;
          return ResetPasswordScreen(
            email: args['email']!,
            code: args['code']!,
          );
        },
      ),
       GoRoute(
        path: '/Preferences',
        builder: (context, state) => const PreferencesPage(),
      ),
       GoRoute(
        path: '/FAQHelpPage',
        builder: (context, state) => const HelpCenterPage(),
      ),
      GoRoute(
        path: '/AboutView',
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: '/PersonalinformationsView',
        builder: (context, state) => const PersonalinformationsView(),
      ),
       GoRoute(
        path: '/Addressesview',
        builder: (context, state) => const Addressesview(),
      ),
    ],
  );

  // ── Safe methods (no context needed) ─────────────────────────
  static void safeNavigateToMainPage() {
    router.go('/');
  }

  static void safeNavigateToIntroduction() {
    router.go('/introduction');
  }

  static void safeNavigateToLogin() {
    router.go('/login');
  }

  static Future navigateToRegister() async {
    await router.push('/register');
  }
   static Future navigateToSettingPReferences() async {
    await router.push('/Preferences');
  }
   static Future navigateToSettingFAQHelp() async {
    await router.push('/FAQHelpPage');
  }
  static Future navigateToSettingAbout() async {
    await router.push('/AboutView');
  }
   static Future navigateToSettingPersonalinformationsView() async {
    await router.push('/PersonalinformationsView');
  }
   static Future navigateToSettingAddressesview() async {
    await router.push('/Addressesview');
  }
  // ── Methods with context ──────────────────────────────────────
  // static void navigateToMainPage(BuildContext context) =>
  //     context.go('/mainPage');
}
