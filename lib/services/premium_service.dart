import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class PremiumService {
  static const String _entitlementId = 'worldpin';

  static const _tag = '[PremiumService]';

  static String _obfuscateKey(String? key) {
    if (key == null || key.length < 8) return '<invalid>';
    return '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
  }

  /// Initializes the RevenueCat SDK
  static Future<void> initialize() async {
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);

    final useProduction = kReleaseMode;
    final envKey = useProduction ? 'REVENUECAT_PROD_API_KEY' : 'REVENUECAT_TEST_API_KEY';
    final apiKey = dotenv.env[envKey];

    debugPrint('$_tag Mode: ${useProduction ? "PRODUCTION" : "TEST"}');
    debugPrint('$_tag Using key from: $envKey');
    debugPrint('$_tag Key present: ${apiKey != null && apiKey.isNotEmpty}');

    if (apiKey == null || apiKey.isEmpty) {
      debugPrint(
        '$_tag ⛔ RevenueCat API Key ($envKey) is missing or empty',
      );
      return;
    }

    debugPrint('$_tag Using key: ${_obfuscateKey(apiKey)}');

    PurchasesConfiguration configuration = PurchasesConfiguration(apiKey);
    await Purchases.configure(configuration);
    debugPrint('$_tag ✅ RevenueCat SDK configured successfully');

    await _logCurrentState();
  }

  /// Logs the current RevenueCat state: config, entitlements, offerings, products
  static Future<void> _logCurrentState() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _logCustomerInfo(customerInfo);
    } catch (e) {
      debugPrint('$_tag Failed to fetch customer info for diagnostics: $e');
    }

    try {
      final offerings = await Purchases.getOfferings();
      _logOfferings(offerings);
    } catch (e) {
      debugPrint('$_tag Failed to fetch offerings for diagnostics: $e');
    }
  }

  /// Logs full CustomerInfo details
  static void _logCustomerInfo(CustomerInfo info) {
    debugPrint('$_tag ─── Customer Info ───');
    debugPrint('$_tag   Original App User ID: ${info.originalAppUserId}');
    debugPrint('$_tag   First Seen: ${info.firstSeen}');
    debugPrint('$_tag   Management URL: ${info.managementURL}');

    final entitlements = info.entitlements.all;
    debugPrint('$_tag   Entitlements (${entitlements.length} total):');
    if (entitlements.isEmpty) {
      debugPrint('$_tag     ⚠️ NENHUMA entitlement encontrada');
    }
    for (final entry in entitlements.entries) {
      final ent = entry.value;
      debugPrint('$_tag     ─ $entry.key ─');
      debugPrint('$_tag       identifier: ${ent.identifier}');
      debugPrint('$_tag       isActive: ${ent.isActive}');
      debugPrint('$_tag       willRenew: ${ent.willRenew}');
      debugPrint('$_tag       periodType: ${ent.periodType}');
      debugPrint('$_tag       latestPurchaseDate: ${ent.latestPurchaseDate}');
      debugPrint(
        '$_tag       originalPurchaseDate: ${ent.originalPurchaseDate}',
      );
      debugPrint('$_tag       expirationDate: ${ent.expirationDate}');
      debugPrint('$_tag       store: ${ent.store}');
      debugPrint('$_tag       productIdentifier: ${ent.productIdentifier}');
      debugPrint('$_tag       isSandbox: ${ent.isSandbox}');
      debugPrint(
        '$_tag       unsubscribeDetectedAt: ${ent.unsubscribeDetectedAt}',
      );
      debugPrint(
        '$_tag       billingIssueDetectedAt: ${ent.billingIssueDetectedAt}',
      );
    }

    final active = info.entitlements.active;
    debugPrint('$_tag   Active Entitlements (${active.length}):');
    if (active.isEmpty) {
      debugPrint('$_tag     ❌ Nenhuma entitlement ativa');
    }
    for (final entry in active.entries) {
      debugPrint('$_tag     ✅ ${entry.key}');
    }

    debugPrint('$_tag   Target _entitlementId: "$_entitlementId"');
    final target = info.entitlements.all[_entitlementId];
    if (target == null) {
      debugPrint(
        '$_tag   ❌ Entitlement "$_entitlementId" NÃO EXISTE no RevenueCat',
      );
    } else if (!target.isActive) {
      debugPrint(
        '$_tag   ❌ Entitlement "$_entitlementId" existe mas NÃO está ativa',
      );
    } else {
      debugPrint('$_tag   ✅ Entitlement "$_entitlementId" está ATIVA');
    }

    // Log active subscriptions
    final subscriptions = info.activeSubscriptions;
    debugPrint('$_tag   Active Subscriptions (${subscriptions.length}):');
    for (final sub in subscriptions) {
      debugPrint('$_tag     📦 $sub');
    }

    // Log non-subscription purchases
    final nonSubscriptions = info.nonSubscriptionTransactions;
    debugPrint(
      '$_tag   Non-Subscription Purchases (${nonSubscriptions.length}):',
    );
    for (final t in nonSubscriptions) {
      debugPrint('$_tag     🛒 ${t.productIdentifier} (${t.purchaseDate})');
    }

    debugPrint('$_tag ─────────────────────');
  }

  /// Logs all offerings and their packages/products
  static void _logOfferings(Offerings offerings) {
    debugPrint('$_tag ─── Offerings ───');
    debugPrint(
      '$_tag   Current Offering: ${offerings.current?.identifier ?? 'none'}',
    );

    final all = offerings.all;
    debugPrint('$_tag   Total Offerings: ${all.length}');
    if (all.isEmpty) {
      debugPrint('$_tag     ⚠️ NENHUMA offering encontrada no RevenueCat');
    }

    for (final entry in all.entries) {
      final offering = entry.value;
      debugPrint('$_tag   ─ Offering: "${entry.key}" ─');
      debugPrint('$_tag     serverDescription: ${offering.serverDescription}');

      final packages = offering.availablePackages;
      debugPrint('$_tag     Packages (${packages.length}):');
      if (packages.isEmpty) {
        debugPrint('$_tag       ⚠️ NENHUM package disponível nesta offering');
      }
      for (final pkg in packages) {
        final storeProduct = pkg.storeProduct;
        debugPrint('$_tag       📦 Package: "${pkg.identifier}"');
        debugPrint('$_tag           productId: "${storeProduct.identifier}"');
        debugPrint('$_tag           title: "${storeProduct.title}"');
        debugPrint(
          '$_tag           description: "${storeProduct.description}"',
        );
        debugPrint('$_tag           price: ${storeProduct.price}');
        debugPrint(
          '$_tag           priceString: "${storeProduct.priceString}"',
        );
        debugPrint('$_tag           currency: "${storeProduct.currencyCode}"');
        debugPrint(
          '$_tag           intro price: ${storeProduct.introductoryPrice?.price}',
        );
        debugPrint(
          '$_tag           subscriptionPeriod: ${storeProduct.subscriptionPeriod}',
        );
        debugPrint(
          '$_tag           offeringId: ${storeProduct.presentedOfferingContext?.offeringIdentifier}',
        );
      }
    }
    debugPrint('$_tag ───────────────────');
  }

  /// Checks if the user has the entitlement
  static Future<bool> isPremium() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _logCustomerInfo(customerInfo);
      final active =
          customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
      debugPrint('$_tag isPremium -> $active');
      return active;
    } catch (e) {
      _logError('isPremium', e);
      return false;
    }
  }

  /// Displays the RevenueCat Paywall
  static Future<PaywallResult> showPaywall() async {
    try {
      final paywallResult = await RevenueCatUI.presentPaywallIfNeeded(
        _entitlementId,
        displayCloseButton: true,
      );
      return paywallResult;
    } catch (e) {
      _logError('showPaywall', e);
      throw Exception('Error showing paywall');
    }
  }

  /// Displays the Customer Center
  static Future<void> showCustomerCenter() async {
    try {
      debugPrint('$_tag showCustomerCenter');
      await RevenueCatUI.presentCustomerCenter();
      debugPrint('$_tag ✅ Customer Center closed');
    } catch (e) {
      _logError('showCustomerCenter', e);
    }
  }

  /// Restores previous purchases
  static Future<bool> restorePurchases() async {
    try {
      debugPrint('$_tag restorePurchases');
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      _logCustomerInfo(customerInfo);
      final active =
          customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
      debugPrint('$_tag ✅ restorePurchases -> isPremium: $active');
      return active;
    } catch (e) {
      _logError('restorePurchases', e);
      return false;
    }
  }

  /// Fetches available offerings
  static Future<Offerings?> getOfferings() async {
    try {
      debugPrint('$_tag getOfferings');
      final offerings = await Purchases.getOfferings();
      _logOfferings(offerings);
      return offerings;
    } catch (e) {
      _logError('getOfferings', e);
      return null;
    }
  }

  /// Centralized error logging — extracts RevenueCat error details
  static void _logError(String method, dynamic error) {
    debugPrint('$_tag ⛔ ERROR in $method');

    if (error is PlatformException) {
      debugPrint('$_tag   code: ${error.code}');
      debugPrint('$_tag   message: ${error.message}');
      debugPrint('$_tag   details: ${error.details}');

      if (error.details is Map) {
        final details = error.details as Map;
        debugPrint(
          '$_tag   readableErrorCode: ${details['readableErrorCode']}',
        );
        debugPrint('$_tag   errorCode: ${details['errorCode']}');
        debugPrint('$_tag   errorMessage: ${details['errorMessage']}');
        debugPrint(
          '$_tag   underlyingErrorMessage: ${details['underlyingErrorMessage']}',
        );
        debugPrint('$_tag   finishable: ${details['finishable']}');

        final errorCode = details['errorCode'];
        if (errorCode == 23) {
          debugPrint(
            '$_tag   ⛔⛔⛔ ERROR 23: ProductNotAvailableForPurchaseError ⛔⛔⛔',
          );
          debugPrint(
            '$_tag   Isso significa que o produto não está disponível para compra.',
          );
          debugPrint('$_tag   Causas comuns:');
          debugPrint(
            '$_tag     1. Produto não configurado no App Store Connect / Google Play Console',
          );
          debugPrint(
            '$_tag     2. Product ID no RevenueCat não bate com o da loja',
          );
          debugPrint(
            '$_tag     3. Assinatura não foi aprovada/setup no App Store Connect',
          );
          debugPrint(
            '$_tag     4. Sandbox vs Production - conta Apple Sandbox não configurada',
          );
          debugPrint(
            '$_tag     5. Apple ID não logado ou sem permissão para testar',
          );
        }
      }
    } else {
      debugPrint('$_tag   exception: $error');
      debugPrint('$_tag   type: ${error.runtimeType}');
    }

    debugPrint('$_tag   stack: ${StackTrace.current}');
  }
}
