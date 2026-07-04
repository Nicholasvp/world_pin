import 'package:flutter/material.dart';
import 'package:sealed_countries/sealed_countries.dart';
import 'package:world_pin/models/uk_countries.dart';

/// Manual translations for UK constituent countries that are not in
/// the standard ISO list.
const Map<String, Map<String, String>> _ukTranslations = {
  'ENG': {'en': 'England', 'pt': 'Inglaterra'},
  'SCO': {'en': 'Scotland', 'pt': 'Escócia'},
  'WAL': {'en': 'Wales', 'pt': 'País de Gales'},
  'NIR': {'en': 'Northern Ireland', 'pt': 'Irlanda do Norte'},
};

/// Returns the translated name for a [WorldCountry] based on the given [locale].
String countryName(WorldCountry country, Locale locale) {
  // Check manual UK translations first
  final ukNames = _ukTranslations[country.code];
  if (ukNames != null) {
    return ukNames[locale.languageCode] ?? country.internationalName;
  }

  // Use the package's built-in translation system
  final langCode = locale.languageCode;
  final language = NaturalLanguage.maybeFromCodeShort(langCode);
  if (language == null) return country.internationalName;

  final name = country.commonNameFor(BasicTypedLocale(language));
  return name.isNotEmpty ? name : country.internationalName;
}

/// Provides a unified list of all countries (standard ISO + UK constituent)
/// and helpers to resolve country codes.
class CountryHelper {
  CountryHelper._();

  /// All countries including UK constituent countries, with GBR removed.
  static final List<WorldCountry> allCountries = [
    ...WorldCountry.list.where((c) => c.code != 'GBR'),
    ...ukConstituentCountries,
  ]..sort((a, b) => a.name.common.compareTo(b.name.common));

  /// Resolves a country code to a [WorldCountry].
  /// Returns `null` if the code is not found.
  static WorldCountry? resolveCountry(String code) {
    // First try standard ISO lookup
    final standard = WorldCountry.maybeFromAnyCode(code);
    if (standard != null) return standard;

    // Then try custom UK countries
    if (UkCountryCodes.isCustomUkCountry(code)) {
      return ukConstituentCountries.firstWhere(
        (c) => c.code == code,
        orElse: () => throw StateError('UK country not found: $code'),
      );
    }

    return null;
  }

  /// Resolves a country code to its display name in the given [locale].
  /// Falls back to the raw code if not found.
  static String resolveName(String code, [Locale locale = const Locale('en')]) {
    final country = resolveCountry(code);
    if (country == null) return code;
    return countryName(country, locale);
  }

  /// Returns the GeoJSON key for a country code.
  /// Custom UK countries use their own code as key.
  static String geoJsonKey(String code) => code;
}
