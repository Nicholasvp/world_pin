import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/visited_countries_repository.dart';

class WishlistCountriesNotifier extends AsyncNotifier<List<String>> {
  late final VisitedCountriesRepository _repo;

  @override
  Future<List<String>> build() async {
    _repo = VisitedCountriesRepository();
    return _repo.getWishlist();
  }

  Future<void> add(String isoCode) async {
    final updated = await _repo.addWishlist(isoCode);
    state = AsyncData(updated);
  }

  Future<void> remove(String isoCode) async {
    final updated = await _repo.removeWishlist(isoCode);
    state = AsyncData(updated);
  }
}

final wishlistCountriesProvider =
    AsyncNotifierProvider<WishlistCountriesNotifier, List<String>>(
  WishlistCountriesNotifier.new,
);
