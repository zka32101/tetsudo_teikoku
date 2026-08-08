import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tetsudo_teikoku/data/models/game_event.dart';
import 'package:tetsudo_teikoku/features/event/event_detail_screen.dart';
import 'package:tetsudo_teikoku/providers/service_providers.dart';
import 'package:tetsudo_teikoku/services/analytics/analytics_service.dart';

class _NoopAnalyticsService extends AnalyticsService {
  @override
  Future<void> logEventCompleted({required String eventID}) async {}
}

GameEvent _event() {
  return GameEvent(
    eventID: 'e1',
    eventType: GameEventType.seasonal,
    stationID: null,
    description: '夏祭りイベント開催中',
    reward: const EventReward(rewardType: 'money', amount: 500),
    startTime: DateTime(2026, 7, 1),
    endTime: DateTime(2026, 7, 31),
  );
}

void main() {
  testWidgets('shows event details and reward preview', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
        ],
        child: MaterialApp(home: EventDetailScreen(event: _event())),
      ),
    );

    expect(find.text('夏祭りイベント開催中'), findsOneWidget);
    expect(find.textContaining('money x500'), findsOneWidget);
  });

  testWidgets('joining the event disables the button and shows joined state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
        ],
        child: MaterialApp(home: EventDetailScreen(event: _event())),
      ),
    );

    await tester.tap(find.byKey(const Key('join_event_button')));
    await tester.pumpAndSettle();

    expect(find.text('参加済み'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.byKey(const Key('join_event_button')),
    );
    expect(button.onPressed, isNull);
  });
}
