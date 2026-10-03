import 'package:connectia/Core/api/AuthRepo.dart';
import 'package:connectia/Core/api/DioClient.dart';
import 'package:connectia/Core/shared/CurrentUser.dart';
import 'package:connectia/Core/shared/Views/VendorRepo.dart';
import 'package:connectia/Core/storage/AppPreferencesService.dart';
import 'package:connectia/Core/storage/TokenStorage.dart';
import 'package:connectia/Features/Account/data/AddressRepo.dart';
import 'package:connectia/Features/Home/data/CategoryRepo.dart';
import 'package:connectia/Features/Home/data/ProductDetailRepo.dart';
import 'package:connectia/Features/Home/data/ProductRepo.dart';
import 'package:connectia/Features/Search/data/SearchRepo.dart';
import 'package:connectia/Features/Wishlist/data/WishlistRepo.dart';
import 'package:connectia/Features/Account/data/FavoritesRepo.dart';
import 'package:connectia/Features/Cart/data/CartRepo.dart';
import 'package:connectia/Features/Cart/data/OrderRepo.dart';
import 'package:connectia/Features/Cart/data/PaymentService.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt locator = GetIt.instance;

Future<void> initLocator() async {
  // ── Core / Singletons ──────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  locator.registerLazySingleton<AppPreferencesService>(
    () => AppPreferencesService(prefs),
  );

  locator.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  locator.registerLazySingleton<TokenStorage>(
    () => TokenStorage(locator<FlutterSecureStorage>()),
  );
  locator.registerLazySingleton<DioClient>(
    () => DioClient(tokenStorage: locator<TokenStorage>()),
  );
  locator.registerLazySingleton<AuthRepo>(
    () => AuthRepo(dio: Dio(), tokenStorage: locator<TokenStorage>()),
  );

  locator.registerLazySingleton<CurrentUser>(() => CurrentUser());

  // ── Repositories ───────────────────────────────────────────
  locator.registerLazySingleton<SearchRepo>(
    () => SearchRepo(client: locator<DioClient>()),
  );
  locator.registerLazySingleton<ProductDetailRepo>(
    () => ProductDetailRepo(client: locator<DioClient>()),
  );
  locator.registerLazySingleton<CategoryRepo>(
    () => CategoryRepo(client: locator<DioClient>()),
  );
  locator.registerLazySingleton<ProductRepo>(
    () => ProductRepo(client: locator<DioClient>()),
  );
  locator.registerLazySingleton<WishlistRepo>(
    () => WishlistRepo(client: locator<DioClient>()),
  );
  locator.registerLazySingleton<VendorRepo>(
    () => VendorRepo(client: locator<DioClient>()),
  );
  locator.registerLazySingleton<FavoritesRepo>(
    () => FavoritesRepo(client: locator<DioClient>()),
  );
  locator.registerLazySingleton<AddressRepo>(
    () => AddressRepo(client: locator<DioClient>()),
  );
  locator.registerLazySingleton<CartRepo>(
    () => CartRepo(client: locator<DioClient>()),
  );
  locator.registerLazySingleton<OrderRepo>(
    () => OrderRepo(client: locator<DioClient>()),
  );
  locator.registerLazySingleton<PaymentService>(
    () => PaymentService(),
  );
}
