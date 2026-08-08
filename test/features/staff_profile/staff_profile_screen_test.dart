import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tetsudo_teikoku/data/models/index.dart';
import 'package:tetsudo_teikoku/features/staff_profile/staff_profile_screen.dart';
import 'package:tetsudo_teikoku/providers/service_providers.dart';
import 'package:tetsudo_teikoku/providers/station_providers.dart';
import 'package:tetsudo_teikoku/services/analytics/analytics_service.dart';
import 'package:tetsudo_teikoku/services/firestore_service.dart';

class _NoopAnalyticsService extends AnalyticsService {
  @override
  Future<void> logTeamFormed({
    required String stationID,
    required double compatibilityBonus,
  }) async {}
}

class _FakeFirestoreService extends FirestoreService {
  TeamFormation? createdTeam;

  @override
  Future<void> createTeamFormation(TeamFormation team) async {
    createdTeam = team;
  }
}

StationStaff _staff(
  String id, {
  int hospitality = 50,
  int efficiency = 50,
  int kindness = 50,
}) {
  return StationStaff(
    staffID: id,
    stationID: 's1',
    userID: 'u1',
    name: id,
    rarity: StaffRarity.sr,
    stats: StaffStats(
      hospitality: hospitality,
      efficiency: efficiency,
      kindness: kindness,
    ),
    level: 3,
    exp: 120,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  testWidgets('shows stats and compatibility list, form-team disabled initially', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          staffByStationProvider(
            's1',
          ).overrideWith((ref) async => [_staff('田中'), _staff('鈴木')]),
        ],
        child: const MaterialApp(
          home: StaffProfileScreen(stationID: 's1', staffID: '田中'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('田中'), findsWidgets);
    expect(find.byKey(const Key('compatibility_tile_鈴木')), findsOneWidget);

    final formButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('form_team_button')),
    );
    expect(formButton.onPressed, isNull);
  });

  testWidgets('selecting a partner enables forming a team and persists it', (
    tester,
  ) async {
    final fakeFirestore = _FakeFirestoreService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          staffByStationProvider(
            's1',
          ).overrideWith((ref) async => [_staff('田中'), _staff('鈴木')]),
          firestoreServiceProvider.overrideWithValue(fakeFirestore),
          analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
        ],
        child: const MaterialApp(
          home: StaffProfileScreen(stationID: 's1', staffID: '田中'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('compatibility_tile_鈴木')));
    await tester.pump();

    final formButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('form_team_button')),
    );
    expect(formButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('form_team_button')));
    await tester.pumpAndSettle();

    expect(fakeFirestore.createdTeam, isNotNull);
    expect(fakeFirestore.createdTeam!.staffID1, '田中');
    expect(fakeFirestore.createdTeam!.staffID2, '鈴木');
  });

  testWidgets('shows not-found message when staffID does not match', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          staffByStationProvider('s1').overrideWith((ref) async => [_staff('田中')]),
        ],
        child: const MaterialApp(
          home: StaffProfileScreen(stationID: 's1', staffID: 'missing'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('駅員が見つかりません'), findsOneWidget);
  });
}
