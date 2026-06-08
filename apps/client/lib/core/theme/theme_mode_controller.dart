import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final darkThemeEnabledProvider =
    StateNotifierProvider<DarkThemeController, bool>((ref) {
  return DarkThemeController();
});

class DarkThemeController extends StateNotifier<bool> {
  DarkThemeController() : super(false) {
    _load();
  }

  static const _storageKey = 'ray_dark_theme_enabled';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_storageKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey, value);
  }
}
