import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class PremiumService {
  static const String _entitlementId = 'Nicholas Pinheiro Pro';

  /// Initializes the RevenueCat SDK
  static Future<void> initialize() async {
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);

    String? apiKey;
    final iosKey = dotenv.env['REVENUECAT_IOS_API_KEY'];
    final androidKey = dotenv.env['REVENUECAT_ANDROID_API_KEY'];

    if (Platform.isIOS && iosKey != null && !iosKey.contains('your_actual')) {
      apiKey = iosKey;
    } else if (Platform.isAndroid &&
        androidKey != null &&
        !androidKey.contains('your_actual')) {
      apiKey = androidKey;
    }

    // Fallback if platform-specific keys are not set or are placeholders
    apiKey ??= dotenv.env['REVENUECAT_API_KEY'];

    if (apiKey == null || apiKey.isEmpty || apiKey.contains('your_actual')) {
      debugPrint('RevenueCat API Key is missing or invalid for this platform');
      return;
    }

    PurchasesConfiguration configuration = PurchasesConfiguration(apiKey);
    await Purchases.configure(configuration);
  }

  /// Checks if the user has the 'Nicholas Pinheiro Pro' entitlement
  static Future<bool> isPremium() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('Error checking premium status: $e');
      return false;
    }
  }

  /// Displays the RevenueCat Paywall
  static Future<PaywallResult> showPaywall({String? offeringIdentifier}) async {
    try {
      Offering? targetOffering;

      // If a specific offering identifier is provided, we fetch it
      if (offeringIdentifier != null) {
        final offerings = await Purchases.getOfferings();
        targetOffering = offerings.all[offeringIdentifier];
      }

      final paywallResult = await RevenueCatUI.presentPaywallIfNeeded(
        _entitlementId,
        offering: targetOffering,
        displayCloseButton: true,
      );
      debugPrint('Paywall result: $paywallResult');
      return paywallResult;
    } catch (e) {
      debugPrint('Error showing paywall: $e');
      throw Exception('Error showing paywall');
    }
  }

  /// Displays the Customer Center
  static Future<void> showCustomerCenter() async {
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      debugPrint('Error showing customer center: $e');
    }
  }

  /// Restores previous purchases
  static Future<bool> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }

  /// Fetches available offerings
  static Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('Error fetching offerings: $e');
      return null;
    }
  }
}
