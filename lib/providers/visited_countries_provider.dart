import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/visited_countries_repository.dart';
import 'premium_provider.dart';
import 'config_provider.dart';

class VisitedCountriesNotifier extends AsyncNotifier<List<String>> {
  late final VisitedCountriesRepository _repo;

  @override
  Future<List<String>> build() async {
    _repo = VisitedCountriesRepository();
    return _repo.getVisited();
  }

  Future<void> add(String isoCode) async {
    final isPremium = ref.read(premiumProvider);
    if (!isPremium) {
      final current = state.value ?? [];
      if (!current.contains(isoCode)) {
        final limit = await ref.read(configLimitProvider.future);
        if (current.length >= limit) {
          await ref
              .read(premiumProvider.notifier)
              .purchaseFullAccess(offeringIdentifier: "50%");
          return;
        }
      }
    }

    final updated = await _repo.addVisited(isoCode);
    state = AsyncData(updated);
  }

  Future<void> remove(String isoCode) async {
    final updated = await _repo.removeVisited(isoCode);
    state = AsyncData(updated);
  }
}

final visitedCountriesProvider =
    AsyncNotifierProvider<VisitedCountriesNotifier, List<String>>(
      VisitedCountriesNotifier.new,
    );
