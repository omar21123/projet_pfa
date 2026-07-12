// lib/core/services/app_preferences_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesService {
  final SharedPreferences _prefs;

  AppPreferencesService(this._prefs);

  // ── Keys (private, defined once) ──────────────────────────
  static const _keyShowOnboarding = 'showOnboarding';
  static const _keyShowLogin = 'showLogin';

  bool get isShowLogin => _prefs.getBool(_keyShowLogin) ?? true;
  bool get isShowOnboarding => _prefs.getBool(_keyShowOnboarding) ?? true;

  Future<void> initialize() async {
    if (!_prefs.containsKey(_keyShowOnboarding)) {
      await _prefs.setBool(_keyShowOnboarding, true); // only the very first time
    }
    if (!_prefs.containsKey(_keyShowLogin)) {
      await _prefs.setBool(_keyShowLogin, true); // only the very first time
    }
  }

  Future<void> setHasSeenOnboarding() =>
      _prefs.setBool(_keyShowOnboarding, false);

  Future<void> setHasSeenLogin() =>
      _prefs.setBool(_keyShowLogin, false);

  // ── Clear everything (e.g. on logout / reset) ────────────────
  Future<void> clearAll() => _prefs.clear();
}