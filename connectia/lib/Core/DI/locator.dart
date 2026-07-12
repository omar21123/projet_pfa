import 'package:connectia/Core/storage/AppPreferencesService.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt locator = GetIt.instance;

Future<void> initLocator() async {
  // ── Core / Singletons ──────────────────────────────────────
    final prefs = await SharedPreferences.getInstance();
  locator.registerLazySingleton<AppPreferencesService>(
    () => AppPreferencesService(prefs),
  );
  // ── Repositories ───────────────────────────────────────────
  // locator.registerLazySingleton<AuthRepository>(
  //   () => AuthRepositoryImpl(locator<ApiClient>()),
  // );

  // ── Cubits / Blocs / ViewModels (factory = new instance each time) ─
  // locator.registerFactory<LoginCubit>(
  //   () => LoginCubit(locator<AuthRepository>()),
  // );
}