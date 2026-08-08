import 'package:purchases_flutter/purchases_flutter.dart';

/// 設計書 §1 マネタイズで定義されたプラン識別子。
/// RevenueCat ダッシュボード側の entitlement 名と一致させること。
class PlanType {
  static const single300 = 'JP_300_1M_RAILWAY';
  static const bundle1200 = 'JP_1200_1M_RAILWAY_BUNDLE';
}

class RevenueCatService {
  bool _configured = false;

  Future<void> configure({
    required String apiKey,
    required String appUserId,
  }) async {
    if (_configured) return;
    await Purchases.configure(
      PurchasesConfiguration(apiKey)..appUserID = appUserId,
    );
    _configured = true;
  }

  Future<Offerings> getOfferings() async => Purchases.getOfferings();

  Future<CustomerInfo> purchasePackage(Package package) async {
    final result = await Purchases.purchase(PurchaseParams.package(package));
    return result.customerInfo;
  }

  Future<CustomerInfo> restorePurchases() async => Purchases.restorePurchases();

  Future<CustomerInfo> getCustomerInfo() async => Purchases.getCustomerInfo();

  String? planTypeFromCustomerInfo(CustomerInfo info) {
    final active = info.entitlements.active;
    if (active.containsKey(PlanType.bundle1200)) return PlanType.bundle1200;
    if (active.containsKey(PlanType.single300)) return PlanType.single300;
    return null;
  }
}
