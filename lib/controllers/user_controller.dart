import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/country_model.dart';
import '../models/user_model.dart';
import '../providers/visited_countries_provider.dart';

class UserController extends Notifier<UserModel?> {
  @override
  UserModel? build() => const UserModel(name: '', email: '');

  void setUser(UserModel user) {
    state = user;
  }

  Future<void> addVisitedCountry(CountryModel country) async {
    if (state == null) return;
    await ref.read(visitedCountriesProvider.notifier).add(country.isoCode);
  }

  Future<void> removeVisitedCountry(String isoCode) async {
    if (state == null) return;
    await ref.read(visitedCountriesProvider.notifier).remove(isoCode);
  }

  void clearUser() {
    state = null;
  }
}

final userProvider = NotifierProvider<UserController, UserModel?>(
  UserController.new,
);
