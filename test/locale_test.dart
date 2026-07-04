import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_pin/providers/locale_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocaleNotifier', () {
    test('default locale is English', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final locale = container.read(localeProvider);
      expect(locale, const Locale('en'));
    });

    test('can switch to Portuguese', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).setLocale(const Locale('pt'));

      final locale = container.read(localeProvider);
      expect(locale, const Locale('pt'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'pt');
    });

    test('can switch back to English', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).setLocale(const Locale('pt'));
      await container.read(localeProvider.notifier).setLocale(const Locale('en'));

      final locale = container.read(localeProvider);
      expect(locale, const Locale('en'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'en');
    });

    test('loadSavedLocale restores saved locale', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_locale', 'pt');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).loadSavedLocale();

      final locale = container.read(localeProvider);
      expect(locale, const Locale('pt'));
    });
  });
}
