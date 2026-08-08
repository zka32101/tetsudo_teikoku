import '../../data/models/town_development.dart';

/// 収益計算(Aha Moment)のたびに町の成長度を伸ばす。
/// 美しさ・賑わいは収益に応じて少しずつ増加し、平均値が一定を超えるごとに
/// レベルが上がる。成長カード(駅詳細画面)が実際に育つようにするためのロジック。
TownDevelopment applyRevenueGrowth(TownDevelopment current, int revenue) {
  final aestheticsGain = (revenue / 1000).clamp(0, 5).round();
  final livelinessGain = (revenue / 800).clamp(0, 5).round();

  final newAesthetics = (current.aesthetics + aestheticsGain).clamp(0, 100);
  final newLiveliness = (current.liveliness + livelinessGain).clamp(0, 100);
  final averageGrowth = (newAesthetics + newLiveliness) / 2;
  // 平均20ごとにレベル+1（最低Lv.1、最大Lv.6）。
  final newLevel = (1 + (averageGrowth / 20).floor()).clamp(1, 6);

  return TownDevelopment(
    townID: current.townID,
    stationID: current.stationID,
    developmentType: current.developmentType,
    level: newLevel,
    aesthetics: newAesthetics,
    liveliness: newLiveliness,
    visualAssetID: current.visualAssetID,
    selectedAt: current.selectedAt,
  );
}
