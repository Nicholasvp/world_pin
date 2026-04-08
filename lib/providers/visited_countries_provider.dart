import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/visited_countries_repository.dart';

class VisitedCountriesNotifier extends AsyncNotifier<List<String>> {
  late final VisitedCountriesRepository _repo;

  @override
  Future<List<String>> build() async {
    _repo = VisitedCountriesRepository();
    return _repo.getAll();
  }

  Future<void> add(String isoCode) async {
    final updated = await _repo.add(isoCode);
    state = AsyncData(updated);
  }

  Future<void> remove(String isoCode) async {
    final updated = await _repo.remove(isoCode);
    state = AsyncData(updated);
  }
}

final visitedCountriesProvider =
    AsyncNotifierProvider<VisitedCountriesNotifier, List<String>>(
  VisitedCountriesNotifier.new,
);
