import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_inventory/providers/language_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Initial state', () {
    test('defaults to English locale', () {
      final lang = LanguageProvider();
      // _load() is async; before it resolves, locale is already set to 'en'
      expect(lang.locale, const Locale('en'));
    });

    test('isArabic is false by default', () {
      final lang = LanguageProvider();
      expect(lang.isArabic, isFalse);
    });
  });

  group('setLanguage', () {
    test('changes locale to French', () async {
      final lang = LanguageProvider();
      await lang.setLanguage('fr');
      expect(lang.locale, const Locale('fr'));
      expect(lang.isArabic, isFalse);
    });

    test('changes locale to Arabic', () async {
      final lang = LanguageProvider();
      await lang.setLanguage('ar');
      expect(lang.locale, const Locale('ar'));
      expect(lang.isArabic, isTrue);
    });

    test('changes back to English from Arabic', () async {
      final lang = LanguageProvider();
      await lang.setLanguage('ar');
      await lang.setLanguage('en');
      expect(lang.locale, const Locale('en'));
      expect(lang.isArabic, isFalse);
    });

    test('notifies listeners on change', () async {
      final lang = LanguageProvider();
      // Wait for constructor's async _load() to complete before counting
      await Future.delayed(const Duration(milliseconds: 50));
      int calls = 0;
      lang.addListener(() => calls++);
      await lang.setLanguage('fr');
      expect(calls, 1);
    });

    test('persists language across instances', () async {
      final lang1 = LanguageProvider();
      await lang1.setLanguage('fr');

      // Simulate app restart — new instance reads from SharedPreferences
      final lang2 = LanguageProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(lang2.locale, const Locale('fr'));
    });
  });

  group('languages list', () {
    test('has 3 entries', () {
      expect(LanguageProvider.languages.length, 3);
    });

    test('contains English', () {
      final en = LanguageProvider.languages.firstWhere((l) => l['code'] == 'en');
      expect(en['name'], 'English');
      expect(en['flag'], '🇬🇧');
    });

    test('contains French', () {
      final fr = LanguageProvider.languages.firstWhere((l) => l['code'] == 'fr');
      expect(fr['name'], 'French');
      expect(fr['native'], 'Français');
      expect(fr['flag'], '🇫🇷');
    });

    test('contains Arabic with Tunisian flag', () {
      final ar = LanguageProvider.languages.firstWhere((l) => l['code'] == 'ar');
      expect(ar['name'], 'Arabic');
      expect(ar['native'], 'العربية');
      expect(ar['flag'], '🇹🇳');
    });

    test('all entries have code, name, native, flag keys', () {
      for (final lang in LanguageProvider.languages) {
        expect(lang.containsKey('code'), isTrue);
        expect(lang.containsKey('name'), isTrue);
        expect(lang.containsKey('native'), isTrue);
        expect(lang.containsKey('flag'), isTrue);
      }
    });
  });
}
