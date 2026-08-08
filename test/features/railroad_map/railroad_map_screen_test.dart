import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tetsudo_teikoku/data/models/index.dart';
import 'package:tetsudo_teikoku/features/railroad_map/railroad_map_screen.dart';
import 'package:tetsudo_teikoku/providers/station_providers.dart';

Station _station(String name, {required DateTime lastUpdated}) {
  return Station(
    stationID: name,
    railroadID: 'tokaido_line',
    name: name,
    position: const GeoPoint2D(lat: 0, lng: 0),
    level: 2,
    revenue: 1000,
    passengersPerDay: 200,
    appealScore: 10,
    developmentType: DevelopmentType.none,
    visualAssetID: null,
    lastUpdated: lastUpdated,
  );
}

void main() {
  testWidgets('shows the station map and history sorted by latest update', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stationsByRailroadProvider('tokaido_line').overrideWith(
            (ref) async => [
              _station('東京', lastUpdated: DateTime(2026, 1, 1)),
              _station('品川', lastUpdated: DateTime(2026, 3, 1)),
            ],
          ),
        ],
        child: const MaterialApp(
          home: RailroadMapScreen(railroadID: 'tokaido_line'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('map_station_東京')), findsOneWidget);
    expect(find.byKey(const Key('map_station_品川')), findsOneWidget);

    final historyTiles = tester.widgetList(find.byType(ListTile)).toList();
    final historyTitles = historyTiles
        .map((w) => (w as ListTile).title)
        .whereType<Text>()
        .map((t) => t.data)
        .where((text) => text != null && text.contains('到達'))
        .toList();
    expect(historyTitles.first, contains('品川'));
  });

  testWidgets('shows empty state when there are no stations', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stationsByRailroadProvider(
            'tokaido_line',
          ).overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: RailroadMapScreen(railroadID: 'tokaido_line'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('この路線にはまだ駅がありません'), findsOneWidget);
  });
}
