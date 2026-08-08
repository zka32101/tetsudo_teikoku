import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tetsudo_teikoku/data/models/index.dart';
import 'package:tetsudo_teikoku/features/share/town_share_screen.dart';
import 'package:tetsudo_teikoku/providers/station_providers.dart';

Station _station() {
  return Station(
    stationID: 's1',
    railroadID: 'tokaido_line',
    name: '熱海',
    position: const GeoPoint2D(lat: 0, lng: 0),
    level: 5,
    revenue: 8000,
    passengersPerDay: 1200,
    appealScore: 88,
    developmentType: DevelopmentType.kanko,
    visualAssetID: null,
    lastUpdated: DateTime(2026, 1, 1),
  );
}

void main() {
  testWidgets('shows the town card and share button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stationDetailProvider('s1').overrideWith((ref) async => _station()),
        ],
        child: const MaterialApp(home: TownShareScreen(stationID: 's1')),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('town_card')), findsOneWidget);
    expect(find.text('熱海'), findsOneWidget);
    expect(find.text('¥8000'), findsOneWidget);
    expect(find.text('88'), findsOneWidget);
    expect(find.byKey(const Key('share_button')), findsOneWidget);
  });

  testWidgets('shows not-found message when station is null', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stationDetailProvider('missing').overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: TownShareScreen(stationID: 'missing')),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('駅が見つかりません'), findsOneWidget);
  });
}
