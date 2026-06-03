import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../repositories/auth_repository.dart';

class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier() : super(false) {
    refreshStatus();
  }

  Future<void> refreshStatus() async {
    try {
      final status = await AuthRepository().getPremiumStatus();
      if (mounted) state = status;
    } catch (_) {}
  }

  Future<void> purchaseFullAccess() async {
    state = true;
    await _syncPremiumToSupabase(true);
  }

  Future<void> _syncPremiumToSupabase(bool isPremium) async {
    try {
      await AuthRepository().updatePremiumStatus(isPremium: isPremium);
    } catch (e) {
      debugPrint('[PremiumNotifier] Erro ao sincronizar premium com Supabase: $e');
    }
  }
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  ref.watch(authProvider);
  return PremiumNotifier();
});
