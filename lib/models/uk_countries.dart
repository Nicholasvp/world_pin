import 'package:sealed_countries/sealed_countries.dart';

class UkCountryCodes {
  UkCountryCodes._();

  static const england = 'ENG';
  static const scotland = 'SCO';
  static const wales = 'WAL';
  static const northernIreland = 'NIR';

  static const all = [england, scotland, wales, northernIreland];

  static bool isCustomUkCountry(String code) => all.contains(code);
}

// ignore: deprecated_member_use_from_same_package
final List<WorldCountry> ukConstituentCountries = [
  WorldCountry.permissive(
    name: const CountryName(
      language: LangEng(),
      official: 'England',
      common: 'England',
    ),
    code: 'ENG',
    codeShort: 'EN',
    emoji: '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
    latLng: const LatLng(53.0688, -1.7126),
    areaMetric: 130279,
    population: 56550000,
    continent: const Europe(),
    altSpellings: const ['England'],
    timezones: const ['UTC+0'],
    tld: const ['.uk'],
    maps: const Maps(googleMaps: ' ', openStreetMaps: ' '),
    idd: const Idd(root: 44, suffixes: [0]),
    bordersCodes: const ['SCO', 'WAL'],
    independent: false,
    unMember: false,
    landlocked: false,
    regionalBlocs: const [],
  ),
  WorldCountry.permissive(
    name: const CountryName(
      language: LangEng(),
      official: 'Scotland',
      common: 'Scotland',
    ),
    code: 'SCO',
    codeShort: 'SC',
    emoji: '🏴󠁧󠁢󠁳󠁣󠁴󠁿',
    latLng: const LatLng(57.0160, -4.4013),
    areaMetric: 77933,
    population: 5454000,
    continent: const Europe(),
    altSpellings: const ['Scotland'],
    timezones: const ['UTC+0'],
    tld: const ['.uk'],
    maps: const Maps(googleMaps: ' ', openStreetMaps: ' '),
    idd: const Idd(root: 44, suffixes: [0]),
    bordersCodes: const ['ENG'],
    independent: false,
    unMember: false,
    landlocked: false,
    regionalBlocs: const [],
  ),
  WorldCountry.permissive(
    name: const CountryName(
      language: LangEng(),
      official: 'Wales',
      common: 'Wales',
    ),
    code: 'WAL',
    codeShort: 'WA',
    emoji: '🏴󠁧󠁢󠁷󠁬󠁳󠁿',
    latLng: const LatLng(52.3382, -3.7563),
    areaMetric: 20779,
    population: 3136000,
    continent: const Europe(),
    altSpellings: const ['Wales'],
    timezones: const ['UTC+0'],
    tld: const ['.uk'],
    maps: const Maps(googleMaps: ' ', openStreetMaps: ' '),
    idd: const Idd(root: 44, suffixes: [0]),
    bordersCodes: const ['ENG'],
    independent: false,
    unMember: false,
    landlocked: false,
    regionalBlocs: const [],
  ),
  WorldCountry.permissive(
    name: const CountryName(
      language: LangEng(),
      official: 'Northern Ireland',
      common: 'Northern Ireland',
    ),
    code: 'NIR',
    codeShort: 'NI',
    emoji: '🇬🇧',
    latLng: const LatLng(54.6081, -6.6937),
    areaMetric: 14130,
    population: 1910000,
    continent: const Europe(),
    altSpellings: const ['Northern Ireland'],
    timezones: const ['UTC+0'],
    tld: const ['.uk'],
    maps: const Maps(googleMaps: ' ', openStreetMaps: ' '),
    idd: const Idd(root: 44, suffixes: [0]),
    bordersCodes: const [],
    independent: false,
    unMember: false,
    landlocked: false,
    regionalBlocs: const [],
  ),
];
