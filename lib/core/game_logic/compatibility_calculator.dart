import '../../data/models/station_staff.dart';

/// 駅員2人のチーム相性ボーナスを算出する。
/// hospitality/efficiency/kindness の差が小さいほど噛み合い、ボーナスが上がる。
/// 差が大きいほどペナルティがかかるが、下限 0.8x は下回らない。
double calculateCompatibilityBonus(StationStaff staff1, StationStaff staff2) {
  final diff =
      (staff1.stats.hospitality - staff2.stats.hospitality).abs() +
      (staff1.stats.efficiency - staff2.stats.efficiency).abs() +
      (staff1.stats.kindness - staff2.stats.kindness).abs();

  // diff=0 → 1.5x, diff が離れるほど減衰。下限 0.8x。
  final bonus = 1.5 - (diff / 100);
  return bonus.clamp(0.8, 1.5);
}

/// チームの合計効率スコア（各人の efficiency 平均 × 相性ボーナス）。
double calculateTotalEfficiency(StationStaff staff1, StationStaff staff2) {
  final avgEfficiency = (staff1.stats.efficiency + staff2.stats.efficiency) / 2;
  final bonus = calculateCompatibilityBonus(staff1, staff2);
  return avgEfficiency * bonus;
}
