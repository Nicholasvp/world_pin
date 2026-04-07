import 'country_model.dart';

class UserModel {
  final String name;
  final String email;
  final String? photo;
  final List<CountryModel> visitedCountries;

  const UserModel({
    required this.name,
    required this.email,
    this.photo,
    this.visitedCountries = const [],
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? photo,
    List<CountryModel>? visitedCountries,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      photo: photo ?? this.photo,
      visitedCountries: visitedCountries ?? this.visitedCountries,
    );
  }
}
