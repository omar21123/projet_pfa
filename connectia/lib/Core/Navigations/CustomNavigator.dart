import 'package:connectia/Core/DI/locator.dart';
import 'package:connectia/Core/shared/Models/BrandModel.dart';
import 'package:connectia/Core/shared/Views/BrandInfoPage.dart';
import 'package:connectia/Core/shared/Views/VendorProfilePage.dart';
import 'package:connectia/Core/storage/AppPreferencesService.dart';
import 'package:connectia/Core/widgets/Terms%20and%20policies/PrivacyPolicyScreen.dart';
import 'package:connectia/Core/widgets/Terms%20and%20policies/TermsOfUseScreen.dart';
import 'package:connectia/Features/Account/views/AboutPage.dart';
import 'package:connectia/Features/Account/views/AddressesView.dart';
import 'package:connectia/Features/Account/data/AddressesCubit.dart';
import 'package:connectia/Features/Account/Widgets/address/AddressDetailPage.dart';
import 'package:connectia/Features/Account/Widgets/address/AddAddressPage.dart';
import 'package:connectia/Features/Account/views/HelpCenterPage.dart';
import 'package:connectia/Features/Account/views/OrdersHistory.dart';
import 'package:connectia/Features/Account/views/PersonalInformationsView.dart';
import 'package:connectia/Features/Account/views/PreferencesPage.dart';
import 'package:connectia/Features/Account/views/ProductsLoved.dart';
import 'package:connectia/Features/Account/views/SecuritySetting.dart';
import 'package:connectia/Features/Account/views/WishLists.dart';
import 'package:connectia/Features/Forgotpassword/presentation/Views/ForgotPasswordEmailScreen.dart';
import 'package:connectia/Features/Forgotpassword/presentation/Views/ResetPasswordScreen.dart';
import 'package:connectia/Features/Forgotpassword/presentation/Views/VerifyResetCodeScreen.dart';
import 'package:connectia/Features/Cart/Views/CheckoutPage.dart';
import 'package:connectia/Features/Cart/data/Cubits/CartCubit.dart';
import 'package:connectia/Features/Home/Views/ProductDetailsPage.dart';
import 'package:connectia/Features/Home/Views/ProductLoadMorePage.dart';
import 'package:connectia/Features/Home/data/ProductRepo.dart';
import 'package:connectia/Features/Login/Login.dart';
import 'package:connectia/Features/Notifications/presentation/View/NotificationsPage.dart';
import 'package:connectia/Features/Onboarding/Views/IntroductionView.dart';
import 'package:connectia/Features/Register/RegisterScreen.dart';
import 'package:connectia/Features/Search/Views/SearchResultsPage.dart';
import 'package:connectia/Features/Search/Views/SearchTypingSuggestions.dart';
import 'package:connectia/Features/main/views/mainPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        builder: (context, state) => BlocProvider(
          create: (_) => AddressesCubit(),
          child: const Addressesview(),
        ),
      ),
      GoRoute(
        path: '/AddressDetailPage',
        builder: (context, state) {
          final addressId = state.extra as int;
          return AddressDetailPage(addressId: addressId);
        },
      ),
      GoRoute(
        path: '/Securitysetting',
        builder: (context, state) => const Securitysetting(),
      ),
      GoRoute(
        path: '/Searchtypingsuggestions',
        builder: (context, state) => const Searchtypingsuggestions(),
      ),
      GoRoute(
        path: '/SearchResultsPage',
        builder: (context, state) {
          final query = state.uri.queryParameters['q'] ?? '';
          return SearchResultsPage(initialQuery: query);
        },
      ),
      GoRoute(
        path: '/ProductDetailsPage',
        builder: (context, state) {
          final params = state.extra as ProductDetailParams?;
          if (params == null) {
            return const Scaffold(
              body: Center(child: Text('Produit introuvable')),
            );
          }
          return ProductDetailsPage(
            productId: params.productId,
            searchTerm: params.searchTerm,
            fromSearch: params.fromSearch,
          );
        },
      ),
      GoRoute(
        path: '/BrandInfoPage',
        builder: (context, state) {
          final brand = state.extra as BrandModel?;
          if (brand == null) {
            return const Scaffold(
              body: Center(child: Text('Marque introuvable')),
            );
          }
          return BrandInfoPage(brand: brand);
        },
      ),
      GoRoute(
        path: '/VendorProfilePage',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return const Scaffold(
              body: Center(child: Text('Vendeur introuvable')),
            );
          }
          return VendorProfilePage(
            vendorProfileId: extra['vendorProfileId'] as int,
            storeName: extra['storeName'] as String? ?? '',
          );
        },
      ),
       GoRoute(
        path: '/Wishlists',
        builder: (context, state) => const Wishlists(),
      ),
    
       GoRoute(
        path: '/Productsloved',
        builder: (context, state) => const Productsloved(),
      ),
       GoRoute(
        path: '/Ordershistory',
        builder: (context, state) => const Ordershistory(),
      ),
       GoRoute(
        path: '/NotificationsPage',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/ProductLoadMorePage',
        builder: (context, state) {
          final params = state.extra as LoadMoreParams?;
          if (params == null) {
            return const Scaffold(
              body: Center(child: Text('Section introuvable')),
            );
          }
          return ProductLoadMorePage(
            endpoint: params.endpoint,
            categoryId: params.categoryId,
          );
        },
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => AddressesCubit()),
            BlocProvider(create: (_) => CartCubit()..fetchCart()),
          ],
          child: const CheckoutPage(),
        ),
      ),
      GoRoute(
        path: '/AddAddressPage',
        builder: (context, state) => BlocProvider(
          create: (_) => AddressesCubit(),
          child: const AddAddressPage(),
        ),
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

  static Future navigateToAddressDetailPage(int addressId) async {
    await router.push('/AddressDetailPage', extra: addressId);
  }

  static Future navigateToSecuritysetting() async {
    await router.push('/Securitysetting');
  }

  static Future navigateToSearchtypingsuggestions() async {
    await router.push('/Searchtypingsuggestions');
  }

  static Future navigateSearchResultsPage(String suggestion) async {
    await router.push(
      '/SearchResultsPage?q=${Uri.encodeComponent(suggestion)}',
    );
  }

  static Future navigateProductDetailsPage(
    String productId, {
    String searchTerm = '',
    bool fromSearch = false,
  }) async {
    await router.push(
      '/ProductDetailsPage',
      extra: ProductDetailParams(
        productId: productId,
        searchTerm: searchTerm,
        fromSearch: fromSearch,
      ),
    );
  }

  static Future navigateBrandInfoPage(BrandModel brand) async {
    await router.push('/BrandInfoPage', extra: brand);
  }

  static Future navigateVendorProfilePage({
    required int vendorProfileId,
    required String storeName,
  }) async {
    await router.push(
      '/VendorProfilePage',
      extra: {
        'vendorProfileId': vendorProfileId,
        'storeName': storeName,
      },
    );
  }

  static Future navigateWishlistsPage( ) async {
    await router.push('/Wishlists');
  }
   static Future navigateProductslovedPage( ) async {
    await router.push('/Productsloved');
  }
   static Future navigateOrdershistoryPage( ) async {
    await router.push('/Ordershistory');
  }
   static Future navigateNotificationsPagePage( ) async {
    await router.push('/NotificationsPage');
  }

  static Future navigateProductLoadMorePage(
    LoadMoreEndpoint endpoint, {
    int? categoryId,
  }) async {
    await router.push(
      '/ProductLoadMorePage',
      extra: LoadMoreParams(endpoint: endpoint, categoryId: categoryId),
    );
  }

  // ── Methods with context ──────────────────────────────────────
  // static void navigateToMainPage(BuildContext context) =>
  //     context.go('/mainPage');
}

class ProductDetailParams {
  final String productId;
  final String searchTerm;
  final bool fromSearch;
  const ProductDetailParams({
    required this.productId,
    this.searchTerm = '',
    this.fromSearch = false,
  });
}

class LoadMoreParams {
  final LoadMoreEndpoint endpoint;
  final int? categoryId;
  const LoadMoreParams({required this.endpoint, this.categoryId});
}