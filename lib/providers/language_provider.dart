import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const _key = 'app_language';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  LanguageProvider() { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code  = prefs.getString(_key) ?? 'en';
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _locale = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    notifyListeners();
  }

  static const languages = [
    {'code': 'en', 'name': 'English',  'native': 'English', 'flag': '🇬🇧'},
    {'code': 'fr', 'name': 'French',   'native': 'Français', 'flag': '🇫🇷'},
    {'code': 'ar', 'name': 'Arabic',   'native': 'العربية',  'flag': '🇹🇳'},
  ];
}
