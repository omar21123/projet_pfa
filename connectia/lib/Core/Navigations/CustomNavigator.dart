import 'package:connectia/Core/DI/locator.dart';
import 'package:connectia/Core/storage/AppPreferencesService.dart';
import 'package:connectia/Features/Login/Login.dart';
import 'package:connectia/Features/Onboarding/Views/IntroductionView.dart';
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

    final goingToIntro = state.matchedLocation == '/introduction';
    final goingToLogin = state.matchedLocation == '/login';

    if (prefs.isShowOnboarding && !goingToIntro) {
      return '/introduction';
    }
    if (!prefs.isShowOnboarding && prefs.isShowLogin && !goingToLogin) {
      return '/login';
    }
    return null; // no redirect needed, proceed normally
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const Mainpage()),
    GoRoute(path: '/introduction', builder: (context, state) => const Introductionview()),
    GoRoute(path: '/login', builder: (context, state) => const Login()),
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
  // ── Methods with context ──────────────────────────────────────
  // static void navigateToMainPage(BuildContext context) =>
  //     context.go('/mainPage');
}