import 'package:firebase_analytics/firebase_analytics.dart';

/// 設計書 §7 計測設計で定義された KPI イベントを送信する。
/// 他の場所から FirebaseAnalytics.instance.logEvent を直接呼ばないこと。
///
/// 全メソッドを async にしていること: `_analytics` getter は Firebase 未初期化時
/// (Phase 2完了前)に同期例外を投げるため、async にせず式を直接returnすると
/// 呼び出し側の catchError では捕まえられない同期クラッシュになる。
class AnalyticsService {
  final FirebaseAnalytics? _analyticsOverride;

  AnalyticsService({FirebaseAnalytics? analytics}) : _analyticsOverride = analytics;

  // Firebase.instance へのアクセスは初回利用時まで遅延させる。
  FirebaseAnalytics get _analytics => _analyticsOverride ?? FirebaseAnalytics.instance;

  Future<void> logHomeViewed() async {
    return _analytics.logEvent(name: 'home_viewed');
  }

  Future<void> logStaffAssigned({
    required String stationID,
    required String staffID,
  }) async {
    return _analytics.logEvent(
      name: 'staff_assigned',
      parameters: {'station_id': stationID, 'staff_id': staffID},
    );
  }

  Future<void> logTeamFormed({
    required String stationID,
    required double compatibilityBonus,
  }) async {
    return _analytics.logEvent(
      name: 'team_formed',
      parameters: {
        'station_id': stationID,
        'compatibility_bonus': compatibilityBonus,
      },
    );
  }

  /// Aha Moment: 駅員配置＆初回収益達成。Day1 60%+ が目標。
  Future<void> logAhaMomentReached({
    required String stationID,
    required int revenue,
  }) async {
    return _analytics.logEvent(
      name: 'aha_moment_reached',
      parameters: {'station_id': stationID, 'revenue': revenue},
    );
  }

  Future<void> logTownDeveloped({
    required String stationID,
    required String developmentType,
  }) async {
    return _analytics.logEvent(
      name: 'town_developed',
      parameters: {
        'station_id': stationID,
        'development_type': developmentType,
      },
    );
  }

  Future<void> logRushHourCompleted({
    required String stationID,
    required int score,
  }) async {
    return _analytics.logEvent(
      name: 'rush_hour_completed',
      parameters: {'station_id': stationID, 'score': score},
    );
  }

  Future<void> logRankingViewed() async {
    return _analytics.logEvent(name: 'ranking_viewed');
  }

  Future<void> logBattleWon({required String opponentUserID}) async {
    return _analytics.logEvent(
      name: 'battle_won',
      parameters: {'opponent_user_id': opponentUserID},
    );
  }

  Future<void> logTimetableDesigned({
    required String railroadID,
    required double efficiencyScore,
  }) async {
    return _analytics.logEvent(
      name: 'timetable_designed',
      parameters: {
        'railroad_id': railroadID,
        'efficiency_score': efficiencyScore,
      },
    );
  }

  Future<void> logEventCompleted({required String eventID}) async {
    return _analytics.logEvent(
      name: 'event_completed',
      parameters: {'event_id': eventID},
    );
  }

  Future<void> logPaywallViewed({required String triggerPoint}) async {
    return _analytics.logEvent(
      name: 'paywall_viewed',
      parameters: {'trigger_point': triggerPoint},
    );
  }

  Future<void> logPurchased({required String planType, required num price}) async {
    return _analytics.logEvent(
      name: 'purchased',
      parameters: {'plan_type': planType, 'price': price},
    );
  }

  Future<void> setUserId(String userId) async => _analytics.setUserId(id: userId);
}
