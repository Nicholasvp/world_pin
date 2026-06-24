import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/visited_countries_repository.dart';
import '../controllers/auth_controller.dart';

class WishlistCountriesNotifier extends AsyncNotifier<List<String>> {
  late VisitedCountriesRepository _repo;

  @override
  Future<List<String>> build() async {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) return [];

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
