import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:tetsudo_teikoku/features/paywall/paywall_screen.dart';
import 'package:tetsudo_teikoku/providers/paywall_providers.dart';
import 'package:tetsudo_teikoku/providers/service_providers.dart';
import 'package:tetsudo_teikoku/services/analytics/analytics_service.dart';

class _NoopAnalyticsService extends AnalyticsService {
  @override
  Future<void> logPaywallViewed({required String triggerPoint}) async {}
}

void main() {
  testWidgets(
    'shows both plans and an unavailable notice when offerings fail to load',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
            offeringsProvider.overrideWith(
              (ref) => Future.error(Exception('not configured')),
            ),
          ],
          child: const MaterialApp(home: PaywallScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('plan_single_300')), findsOneWidget);
      expect(find.byKey(const Key('plan_bundle_1200')), findsOneWidget);
      expect(find.byKey(const Key('paywall_unavailable_notice')), findsOneWidget);

      final singleButton = tester.widget<ElevatedButton>(
        find.descendant(
          of: find.byKey(const Key('plan_single_300')),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(singleButton.onPressed, isNull);
    },
  );

  testWidgets('shows a loading indicator while offerings are loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
          offeringsProvider.overrideWith((ref) => Completer<Offerings>().future),
        ],
        child: const MaterialApp(home: PaywallScreen()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
