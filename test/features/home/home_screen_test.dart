import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tetsudo_teikoku/data/models/index.dart';
import 'package:tetsudo_teikoku/features/home/home_screen.dart';
import 'package:tetsudo_teikoku/providers/service_providers.dart';
import 'package:tetsudo_teikoku/providers/station_providers.dart';
import 'package:tetsudo_teikoku/providers/user_providers.dart';
import 'package:tetsudo_teikoku/services/analytics/analytics_service.dart';

class _NoopAnalyticsService extends AnalyticsService {
  @override
  Future<void> logHomeViewed() async {}

  @override
  Future<void> logEventCompleted({required String eventID}) async {}
}

Station _station(String id, {int revenue = 1000}) {
  return Station(
    stationID: id,
    railroadID: 'tokaido_line',
    name: id,
    position: const GeoPoint2D(lat: 0, lng: 0),
    level: 1,
    revenue: revenue,
    passengersPerDay: 200,
    appealScore: 10,
    developmentType: DevelopmentType.none,
    visualAssetID: null,
    lastUpdated: DateTime(2026, 1, 1),
  );
}

void main() {
  testWidgets('shows station list once loaded', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
          userProfileProvider.overrideWith((ref) async => null),
          stationsByRailroadProvider(
            'tokaido_line',
          ).overrideWith((ref) async => [_station('東京'), _station('品川')]),
          activeEventsProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('鉄道帝国'), findsOneWidget);
    expect(find.byKey(const Key('station_list')), findsOneWidget);
    expect(find.text('東京'), findsOneWidget);
    expect(find.text('品川'), findsOneWidget);
  });

  testWidgets('shows empty state when there are no stations', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
          userProfileProvider.overrideWith((ref) async => null),
          stationsByRailroadProvider(
            'tokaido_line',
          ).overrideWith((ref) async => []),
          activeEventsProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('まだ駅がありません'), findsOneWidget);
  });

  testWidgets('shows the event banner when an event is active', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
          userProfileProvider.overrideWith((ref) async => null),
          stationsByRailroadProvider(
            'tokaido_line',
          ).overrideWith((ref) async => []),
          activeEventsProvider.overrideWith(
            (ref) async => [
              GameEvent(
                eventID: 'e1',
                eventType: GameEventType.seasonal,
                stationID: null,
                description: '夏祭りイベント開催中',
                reward: const EventReward(rewardType: 'money', amount: 100),
                startTime: DateTime(2026, 7, 1),
                endTime: DateTime(2026, 7, 31),
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('event_banner')), findsOneWidget);
    expect(find.text('夏祭りイベント開催中'), findsOneWidget);
  });

  testWidgets('tapping the map icon opens the railroad map screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
          userProfileProvider.overrideWith((ref) async => null),
          stationsByRailroadProvider(
            'tokaido_line',
          ).overrideWith((ref) async => [_station('東京')]),
          activeEventsProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_railroad_map_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('railroad_map_list')), findsOneWidget);
  });

  testWidgets('tapping the ranking icon opens the ranking screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
          userProfileProvider.overrideWith((ref) async => null),
          stationsByRailroadProvider(
            'tokaido_line',
          ).overrideWith((ref) async => []),
          activeEventsProvider.overrideWith((ref) async => []),
          topRankingsProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_ranking_button')));
    await tester.pumpAndSettle();

    expect(find.text('まだランキングデータがありません'), findsOneWidget);
  });

  testWidgets('tapping the event banner opens the event detail screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
          userProfileProvider.overrideWith((ref) async => null),
          stationsByRailroadProvider(
            'tokaido_line',
          ).overrideWith((ref) async => []),
          activeEventsProvider.overrideWith(
            (ref) async => [
              GameEvent(
                eventID: 'e1',
                eventType: GameEventType.seasonal,
                stationID: null,
                description: '夏祭りイベント開催中',
                reward: const EventReward(rewardType: 'money', amount: 100),
                startTime: DateTime(2026, 7, 1),
                endTime: DateTime(2026, 7, 31),
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('event_banner')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('join_event_button')), findsOneWidget);
  });
}
