import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/config_repository.dart';

final configRepositoryProvider = Provider<ConfigRepository>((ref) {
  return ConfigRepository();
});

final configLimitProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(configRepositoryProvider);
  return repository.getLimitFreeCountries();
});
