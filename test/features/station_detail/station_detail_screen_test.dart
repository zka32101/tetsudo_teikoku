import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tetsudo_teikoku/data/models/index.dart';
import 'package:tetsudo_teikoku/features/station_detail/station_detail_screen.dart';
import 'package:tetsudo_teikoku/providers/service_providers.dart';
import 'package:tetsudo_teikoku/providers/station_providers.dart';
import 'package:tetsudo_teikoku/services/analytics/analytics_service.dart';
import 'package:tetsudo_teikoku/services/firestore_service.dart';

class _NoopAnalyticsService extends AnalyticsService {
  @override
  Future<void> logAhaMomentReached({
    required String stationID,
    required int revenue,
  }) async {}
}

class _FakeFirestoreService extends FirestoreService {
  TownDevelopment? savedDevelopment;

  @override
  Future<void> createTownDevelopment(TownDevelopment development) async {
    savedDevelopment = development;
  }
}

Station _station({DevelopmentType type = DevelopmentType.onsen}) {
  return Station(
    stationID: 's1',
    railroadID: 'tokaido_line',
    name: '熱海',
    position: const GeoPoint2D(lat: 0, lng: 0),
    level: 3,
    revenue: 5000,
    passengersPerDay: 800,
    appealScore: 42,
    developmentType: type,
    visualAssetID: null,
    lastUpdated: DateTime(2026, 1, 1),
  );
}

TownDevelopment _townDevelopment({int level = 2, int aesthetics = 60, int liveliness = 40}) {
  return TownDevelopment(
    townID: 's1_town',
    stationID: 's1',
    developmentType: DevelopmentType.onsen,
    level: level,
    aesthetics: aesthetics,
    liveliness: liveliness,
    visualAssetID: null,
    selectedAt: DateTime(2026, 1, 1),
  );
}

StationStaff _staff(String id) {
  return StationStaff(
    staffID: id,
    stationID: 's1',
    userID: 'u1',
    name: id,
    rarity: StaffRarity.sr,
    stats: const StaffStats(hospitality: 50, efficiency: 50, kindness: 50),
    level: 1,
    exp: 0,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  testWidgets('shows station stats and revenue', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stationDetailProvider('s1').overrideWith((ref) async => _station()),
          staffByStationProvider('s1').overrideWith((ref) async => []),
          townDevelopmentProvider('s1').overrideWith((ref) async => null),
        ],
        child: const MaterialApp(
          home: StationDetailScreen(stationID: 's1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('熱海'), findsOneWidget);
    expect(find.text('¥5000'), findsOneWidget);
    expect(find.byKey(const Key('station_townscape')), findsOneWidget);
    expect(find.text('まだ駅員が配置されていません'), findsOneWidget);
  });

  testWidgets('shows assigned staff chips', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stationDetailProvider('s1').overrideWith((ref) async => _station()),
          staffByStationProvider(
            's1',
          ).overrideWith((ref) async => [_staff('田中'), _staff('鈴木')]),
        ],
        child: const MaterialApp(
          home: StationDetailScreen(stationID: 's1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('staff_chip_田中')), findsOneWidget);
    expect(find.byKey(const Key('staff_chip_鈴木')), findsOneWidget);
  });

  testWidgets('tapping the develop-town button navigates to the development screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stationDetailProvider(
            's1',
          ).overrideWith((ref) async => _station(type: DevelopmentType.none)),
          staffByStationProvider('s1').overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: StationDetailScreen(stationID: 's1')),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('go_develop_town_button')));
    await tester.pumpAndSettle();

    expect(find.text('町の発展を選ぼう'), findsOneWidget);
  });

  testWidgets('tapping a staff chip navigates to that staff\'s profile', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stationDetailProvider('s1').overrideWith((ref) async => _station()),
          staffByStationProvider(
            's1',
          ).overrideWith((ref) async => [_staff('田中'), _staff('鈴木')]),
        ],
        child: const MaterialApp(home: StationDetailScreen(stationID: 's1')),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('staff_chip_田中')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('compatibility_tile_鈴木')), findsOneWidget);
  });

  testWidgets('calculating revenue shows the result dialog', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
          stationDetailProvider('s1').overrideWith((ref) async => _station()),
          staffByStationProvider(
            's1',
          ).overrideWith((ref) async => [_staff('田中')]),
        ],
        child: const MaterialApp(home: StationDetailScreen(stationID: 's1')),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('calculate_revenue_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('revenue_result_dialog')), findsOneWidget);
  });

  testWidgets('calculating revenue grows the town development stats', (
    tester,
  ) async {
    final fakeFirestore = _FakeFirestoreService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
          firestoreServiceProvider.overrideWithValue(fakeFirestore),
          stationDetailProvider('s1').overrideWith((ref) async => _station()),
          staffByStationProvider(
            's1',
          ).overrideWith((ref) async => [_staff('田中')]),
          townDevelopmentProvider(
            's1',
          ).overrideWith((ref) async => _townDevelopment()),
        ],
        child: const MaterialApp(home: StationDetailScreen(stationID: 's1')),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('calculate_revenue_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(fakeFirestore.savedDevelopment, isNotNull);
    expect(fakeFirestore.savedDevelopment!.aesthetics, greaterThan(60));
  });

  testWidgets('shows the town growth card once a station has developed', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stationDetailProvider(
            's1',
          ).overrideWith((ref) async => _station(type: DevelopmentType.onsen)),
          staffByStationProvider('s1').overrideWith((ref) async => []),
          townDevelopmentProvider(
            's1',
          ).overrideWith((ref) async => _townDevelopment(level: 3)),
        ],
        child: const MaterialApp(home: StationDetailScreen(stationID: 's1')),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('town_growth_card')), findsOneWidget);
    expect(find.text('Lv.3'), findsOneWidget);
  });

  testWidgets('hides the town growth card when the station has not developed', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stationDetailProvider(
            's1',
          ).overrideWith((ref) async => _station(type: DevelopmentType.none)),
          staffByStationProvider('s1').overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: StationDetailScreen(stationID: 's1')),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('town_growth_card')), findsNothing);
  });

  testWidgets('shows not-found message when station is null', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stationDetailProvider('missing').overrideWith((ref) async => null),
          staffByStationProvider('missing').overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: StationDetailScreen(stationID: 'missing'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('駅が見つかりません'), findsOneWidget);
  });
}
