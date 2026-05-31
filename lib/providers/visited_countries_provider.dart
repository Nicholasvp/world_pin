import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/visited_countries_repository.dart';
import '../controllers/auth_controller.dart';
import 'premium_provider.dart';
import 'config_provider.dart';

class VisitedCountriesNotifier extends AsyncNotifier<List<String>> {
  late VisitedCountriesRepository _repo;

  @override
  Future<List<String>> build() async {
    // Observa o estado de autenticação — quando mudar (login/logout),
    // o provider é invalidado e recarregado com os dados do novo utilizador.
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) return [];

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
          await ref.read(premiumProvider.notifier).purchaseFullAccess();
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
