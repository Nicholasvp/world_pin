import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
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
    final isPro = customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    state = isPro;
  }

  Future<void> refreshStatus() async {
    state = await PremiumService.isPremium();
  }

  Future<void> purchaseFullAccess() async {
    await PremiumService.showPaywall();
    await refreshStatus();
  }

  Future<void> restore() async {
    final success = await PremiumService.restorePurchases();
    state = success;
  }
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier();
});
