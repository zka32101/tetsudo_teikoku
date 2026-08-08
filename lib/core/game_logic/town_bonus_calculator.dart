import '../../data/models/station.dart';

/// 町の発展タイプごとの収益倍率ボーナス。
/// 温泉=集客力重視 / 商業=収益重視 / 観光=魅力度重視、で特化方向を変える。
double calculateTownBonusFromDevelopment(DevelopmentType type) {
  switch (type) {
    case DevelopmentType.onsen:
      return 1.3;
    case DevelopmentType.shogyo:
      return 1.5;
    case DevelopmentType.kanko:
      return 1.2;
    case DevelopmentType.none:
      return 1.0;
  }
}
