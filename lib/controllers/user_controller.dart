import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/country_model.dart';
import '../models/user_model.dart';

class UserController extends Notifier<UserModel?> {
  @override
  UserModel? build() => const UserModel(name: '', email: '');

  void setUser(UserModel user) {
    state = user;
  }

  void addVisitedCountry(CountryModel country) {
    if (state == null) return;
    state = state!.copyWith(
      visitedCountries: [...state!.visitedCountries, country],
    );
  }

  void removeVisitedCountry(String countryName) {
    if (state == null) return;
    state = state!.copyWith(
      visitedCountries: state!.visitedCountries
          .where((c) => c.name != countryName)
          .toList(),
    );
  }

  void clearUser() {
    state = null;
  }
}

final userProvider = NotifierProvider<UserController, UserModel?>(
  UserController.new,
);
