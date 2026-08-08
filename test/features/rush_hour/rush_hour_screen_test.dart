import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tetsudo_teikoku/features/rush_hour/rush_hour_screen.dart';
import 'package:tetsudo_teikoku/providers/service_providers.dart';
import 'package:tetsudo_teikoku/services/analytics/analytics_service.dart';

class _NoopAnalyticsService extends AnalyticsService {
  @override
  Future<void> logRushHourCompleted({
    required String stationID,
    required int score,
  }) async {}
}

void main() {
  testWidgets('mounts the Flame game and shows no result before completion', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
        ],
        child: const MaterialApp(home: RushHourScreen(stationID: 's1')),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('rush_hour_game_widget')), findsOneWidget);
    expect(find.byKey(const Key('rush_hour_result_card')), findsNothing);
  });
}
