import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'service_providers.dart';

/// RevenueCat Offerings。RevenueCat未設定(Phase 2完了前)の間はエラーになる想定。
final offeringsProvider = FutureProvider<Offerings>((ref) {
  final revenueCat = ref.watch(revenueCatServiceProvider);
  return revenueCat.getOfferings();
});
