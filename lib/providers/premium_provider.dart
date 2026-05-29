import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/paywall_result.dart';
import '../repositories/auth_repository.dart';
import '../services/premium_service.dart';

class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier() : super(false) {
    _init();
  }

  Future<void> _init() async {
    // Listen to customer info changes
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      _updateStatus(customerInfo);
    });

    // Initial check
    final status = await PremiumService.isPremium();
    state = status;
  }

  void _updateStatus(CustomerInfo customerInfo) {
    const entitlementId = 'Nicholas Pinheiro Pro';
    final isPro =
        customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    state = isPro;
  }

  Future<void> refreshStatus() async {
    state = await PremiumService.isPremium();
  }

  Future<void> purchaseFullAccess({String? offeringIdentifier}) async {
    final result = await PremiumService.showPaywall(
      offeringIdentifier: offeringIdentifier,
    );
    // If the paywall result indicates a successful purchase, we can safely set premium = true
    if (result == PaywallResult.purchased) {
      state = true;
    } else {
      // Fallback to checking current status via PremiumService
      await refreshStatus();
    }
    await _syncPremiumToSupabase(state);
  }

  Future<void> restore() async {
    final success = await PremiumService.restorePurchases();
    state = success;
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
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier();
});
