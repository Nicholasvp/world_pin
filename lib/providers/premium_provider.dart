import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/paywall_result.dart';
import '../controllers/auth_controller.dart';
import '../repositories/auth_repository.dart';
import '../services/premium_service.dart';

class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier() : super(false) {
    _init();
  }

  late void Function(CustomerInfo) _customerInfoListener;

  Future<void> _init() async {
    _customerInfoListener = (CustomerInfo customerInfo) {
      if (mounted) _updateStatus();
    };

    Purchases.addCustomerInfoUpdateListener(_customerInfoListener);

    await _updateStatus();
  }

  Future<void> _updateStatus() async {
    final repo = AuthRepository();
    final isPro = await repo.getPremiumStatus();
    if (mounted) state = isPro;
  }

  Future<void> refreshStatus() async {
    final status = await PremiumService.isPremium();
    if (mounted) state = status;
  }

  Future<void> purchaseFullAccess({String? offeringIdentifier}) async {
    final result = await PremiumService.showPaywall(
      offeringIdentifier: offeringIdentifier,
    );
    if (result == PaywallResult.purchased) {
      if (mounted) state = true;
    } else {
      await refreshStatus();
    }
    if (mounted) await _syncPremiumToSupabase(state);
  }

  Future<void> restore() async {
    final success = await PremiumService.restorePurchases();
    if (mounted) state = success;
    await _syncPremiumToSupabase(success);
  }

  Future<void> _syncPremiumToSupabase(bool isPremium) async {
    try {
      final repo = AuthRepository();
      await repo.updatePremiumStatus(isPremium: isPremium);
    } catch (e) {
      debugPrint('Erro ao sincronizar premium com Supabase: $e');
    }
  }

  @override
  void dispose() {
    Purchases.removeCustomerInfoUpdateListener(_customerInfoListener);
    super.dispose();
  }
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  ref.watch(authProvider);
  return PremiumNotifier();
});
