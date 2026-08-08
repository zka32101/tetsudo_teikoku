import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tetsudo_teikoku/data/models/pvp_ranking.dart';
import 'package:tetsudo_teikoku/data/models/user_profile.dart';
import 'package:tetsudo_teikoku/features/ranking/ranking_screen.dart';
import 'package:tetsudo_teikoku/providers/service_providers.dart';
import 'package:tetsudo_teikoku/providers/station_providers.dart';
import 'package:tetsudo_teikoku/providers/user_providers.dart';
import 'package:tetsudo_teikoku/services/analytics/analytics_service.dart';

class _NoopAnalyticsService extends AnalyticsService {
  @override
  Future<void> logBattleWon({required String opponentUserID}) async {}
}

PvPRanking _ranking(String userID, int rank, int appealScore) {
  return PvPRanking(
    rankingID: 'r_$userID',
    userID: userID,
    appealScore: appealScore,
    rank: rank,
    weeklyBattles: 5,
    weeklyWins: 3,
    lastUpdated: DateTime(2026, 1, 1),
  );
}

void main() {
  testWidgets('shows the ranking list ordered by rank', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) async => null),
          topRankingsProvider.overrideWith(
            (ref) async => [
              _ranking('alice', 1, 500),
              _ranking('bob', 2, 400),
            ],
          ),
        ],
        child: const MaterialApp(home: RankingScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ranking_list')), findsOneWidget);
    expect(find.byKey(const Key('ranking_tile_alice')), findsOneWidget);
    expect(find.byKey(const Key('ranking_tile_bob')), findsOneWidget);
    expect(find.text('魅力度 500'), findsOneWidget);
  });

  testWidgets('shows empty state when there is no ranking data', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) async => null),
          topRankingsProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: RankingScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('まだランキングデータがありません'), findsOneWidget);
  });

  testWidgets('battle button is hidden for my own tile but shown for others', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
          userProfileProvider.overrideWith(
            (ref) async => UserProfile.initial(userID: 'alice', name: 'alice'),
          ),
          topRankingsProvider.overrideWith(
            (ref) async => [
              _ranking('alice', 1, 500),
              _ranking('bob', 2, 400),
            ],
          ),
        ],
        child: const MaterialApp(home: RankingScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('battle_button_alice')), findsNothing);
    expect(find.byKey(const Key('battle_button_bob')), findsOneWidget);
  });

  testWidgets('requesting a battle shows the outcome dialog', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
          userProfileProvider.overrideWith(
            (ref) async => UserProfile.initial(userID: 'alice', name: 'alice'),
          ),
          topRankingsProvider.overrideWith(
            (ref) async => [
              _ranking('alice', 1, 500),
              _ranking('bob', 2, 400),
            ],
          ),
        ],
        child: const MaterialApp(home: RankingScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('battle_button_bob')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('battle_result_dialog')), findsOneWidget);
    expect(find.text('勝利！'), findsOneWidget);
  });
}
