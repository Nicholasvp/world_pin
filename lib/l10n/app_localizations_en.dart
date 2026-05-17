// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'World Pin';

  @override
  String get tagline => 'Mark your adventures around the world';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get enter => 'Enter';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get createAccount => 'Create Account';

  @override
  String get name => 'Name';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get myTrips => 'MY TRIPS';

  @override
  String get visited => 'Visited';

  @override
  String get wishlist => 'Wishlist';

  @override
  String get markCountry => 'Mark Country';

  @override
  String get searchCountry => 'Where did you go?';

  @override
  String get noCountriesFound => 'No countries found.';

  @override
  String get clickToSelect => 'Click to select';

  @override
  String selectDestination(Object country) {
    return 'What do you want to mark for $country?';
  }

  @override
  String get alreadyVisited => 'Already visited';

  @override
  String get wantToGo => 'Want to go';

  @override
  String get removeCountry => 'Remove Country';

  @override
  String confirmRemove(Object country) {
    return 'Do you want to remove $country from your list?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String removed(Object country) {
    return '$country removed';
  }

  @override
  String error(Object message) {
    return 'Error: $message';
  }

  @override
  String get emptyVisited => 'You haven\'t marked any visited countries yet.';

  @override
  String get emptyWishlist => 'Your wishlist is empty.';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmTitle => 'Log Out';

  @override
  String get logoutConfirmMessage => 'Are you sure you want to log out?';

  @override
  String get profile => 'Profile';

  @override
  String get visitedCountriesLabel => 'Visited countries:';
}
