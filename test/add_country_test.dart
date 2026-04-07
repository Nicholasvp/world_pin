import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_pin/controllers/user_controller.dart';
import 'package:world_pin/models/country_model.dart';
import 'package:world_pin/models/user_model.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('addVisitedCountry', () {
    test('does nothing when user is cleared', () {
      container.read(userProvider.notifier).clearUser();

      container.read(userProvider.notifier).addVisitedCountry(
            CountryModel(
              name: 'Brazil',
              isoCode: 'BRA',
              localization: '-15.78, -47.93',
              date: _kDate,
            ),
          );

      expect(container.read(userProvider), isNull);
    });

    test('adds country to visited list', () {
      container.read(userProvider.notifier).setUser(
            UserModel(name: 'Julia', email: 'julia@example.com'),
          );

      container.read(userProvider.notifier).addVisitedCountry(
            CountryModel(
              name: 'Brazil',
              isoCode: 'BRA',
              localization: '-15.78, -47.93',
              date: _kDate,
            ),
          );

      final visited = container.read(userProvider)!.visitedCountries;
      expect(visited, hasLength(1));
      expect(visited.first.name, 'Brazil');
      expect(visited.first.localization, '-15.78, -47.93');
      expect(visited.first.date, _kDate);
    });

    test('preserves existing countries when adding a new one', () {
      container.read(userProvider.notifier).setUser(
            UserModel(
              name: 'Julia',
              email: 'julia@example.com',
              visitedCountries: [
                CountryModel(
                  name: 'Argentina',
                  isoCode: 'ARG',
                  localization: '-34.0, -64.0',
                  date: _kDate,
                ),
              ],
            ),
          );

      container.read(userProvider.notifier).addVisitedCountry(
            CountryModel(
              name: 'Brazil',
              isoCode: 'BRA',
              localization: '-15.78, -47.93',
              date: _kDate,
            ),
          );

      final visited = container.read(userProvider)!.visitedCountries;
      expect(visited, hasLength(2));
      expect(visited.map((c) => c.name), containsAll(['Argentina', 'Brazil']));
    });

    test('allows adding the same country more than once', () {
      container.read(userProvider.notifier).setUser(
            UserModel(name: 'Julia', email: 'julia@example.com'),
          );

      final country = CountryModel(
        name: 'Brazil',
        isoCode: 'BRA',
        localization: '-15.78, -47.93',
        date: _kDate,
      );

      container.read(userProvider.notifier).addVisitedCountry(country);
      container.read(userProvider.notifier).addVisitedCountry(country);

      expect(container.read(userProvider)!.visitedCountries, hasLength(2));
    });
  });
}

final _kDate = DateTime(2024, 6, 15);
