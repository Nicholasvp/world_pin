import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/visited_countries_repository.dart';
import '../controllers/auth_controller.dart';

class VisitedCountriesNotifier extends AsyncNotifier<List<String>> {
  late VisitedCountriesRepository _repo;

  @override
  Future<List<String>> build() async {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) return [];

    _repo = VisitedCountriesRepository();
    return _repo.getVisited();
  }

  Future<void> add(String isoCode) async {
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
