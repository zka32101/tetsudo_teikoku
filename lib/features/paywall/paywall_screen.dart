import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../providers/paywall_providers.dart';
import '../../providers/service_providers.dart';
import '../../services/revenuecat_service.dart';

/// ペイウォール画面（設計書§5-9）。月¥300単体プランとセット¥1,200プランを表示する。
class PaywallScreen extends ConsumerStatefulWidget {
  final String triggerPoint;

  const PaywallScreen({super.key, this.triggerPoint = 'aha_moment'});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    ref
        .read(analyticsServiceProvider)
        .logPaywallViewed(triggerPoint: widget.triggerPoint)
        .catchError((_) {});
  }

  Future<void> _purchase(Package package, String planType, num price) async {
    if (_purchasing) return;
    setState(() => _purchasing = true);

    try {
      await ref.read(revenueCatServiceProvider).purchasePackage(package);
      await ref
          .read(analyticsServiceProvider)
          .logPurchased(planType: planType, price: price)
          .catchError((_) {});
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offeringsAsync = ref.watch(offeringsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('プランを選ぶ')),
      body: offeringsAsync.when(
        data: (offerings) {
          final current = offerings.current;
          final singlePackage = current?.availablePackages
              .where((p) => p.identifier == PlanType.single300)
              .firstOrNullSafe;
          final bundlePackage = current?.availablePackages
              .where((p) => p.identifier == PlanType.bundle1200)
              .firstOrNullSafe;

          return _PaywallBody(
            purchasing: _purchasing,
            single300Available: singlePackage != null,
            bundle1200Available: bundlePackage != null,
            onPurchaseSingle: singlePackage == null
                ? null
                : () => _purchase(singlePackage, PlanType.single300, 300),
            onPurchaseBundle: bundlePackage == null
                ? null
                : () => _purchase(bundlePackage, PlanType.bundle1200, 1200),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _PaywallBody(
          purchasing: false,
          single300Available: false,
          bundle1200Available: false,
          onPurchaseSingle: null,
          onPurchaseBundle: null,
          unavailableNotice: '課金機能は準備中です。しばらくお待ちください。',
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNullSafe => isEmpty ? null : first;
}

class _PaywallBody extends StatelessWidget {
  final bool purchasing;
  final bool single300Available;
  final bool bundle1200Available;
  final VoidCallback? onPurchaseSingle;
  final VoidCallback? onPurchaseBundle;
  final String? unavailableNotice;

  const _PaywallBody({
    required this.purchasing,
    required this.single300Available,
    required this.bundle1200Available,
    required this.onPurchaseSingle,
    required this.onPurchaseBundle,
    this.unavailableNotice,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (unavailableNotice != null) ...[
            Text(unavailableNotice!, key: const Key('paywall_unavailable_notice')),
            const SizedBox(height: 16),
          ],
          Card(
            child: ListTile(
              key: const Key('plan_single_300'),
              title: const Text('単教科プラン'),
              subtitle: const Text('月¥300'),
              trailing: ElevatedButton(
                onPressed: purchasing ? null : onPurchaseSingle,
                child: const Text('選ぶ'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              key: const Key('plan_bundle_1200'),
              title: const Text('セットプラン(全機能+スターマスター)'),
              subtitle: const Text('月¥1,200'),
              trailing: ElevatedButton(
                onPressed: purchasing ? null : onPurchaseBundle,
                child: const Text('選ぶ'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
