import '../../data/models/station.dart';
import '../../data/models/station_staff.dart';
import 'town_bonus_calculator.dart';

/// Aha Moment（駅員配置→月間収益計算）のコアロジック。
/// 本来は Cloud Functions 側で計算する想定（設計書§6 POST /station/{id}/develop
/// 相当）だが、Firebase未設定の間はクライアント側でスタブ実装する。
/// - 駅員1人あたり efficiency×10 の収益
/// - 乗客数から passengersPerDay×2 の基礎収益
/// - 町の発展タイプによるボーナス倍率
int calculateMonthlyRevenue({
  required List<StationStaff> staff,
  required DevelopmentType developmentType,
  required int passengersPerDay,
}) {
  final staffRevenue = staff.fold<int>(
    0,
    (sum, s) => sum + s.stats.efficiency * 10,
  );
  final baseRevenue = passengersPerDay * 2;
  final bonus = calculateTownBonusFromDevelopment(developmentType);
  return ((staffRevenue + baseRevenue) * bonus).round();
}
