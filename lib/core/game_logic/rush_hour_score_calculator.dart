/// ラッシュアワーミニゲームのスコア算出。
/// - 通常乗客: さばくと加点、取りこぼすと減点
/// - VIP乗客: 高得点だが取りこぼすと減点も大きい
/// - 邪魔な乗客: タップしてしまうと減点(タップせず見送るのが正解)
/// - コンボ: ミス無く連続でさばくほどボーナス倍率が上がる
int calculateRushHourScore({
  required int passengersHandled,
  required int passengersMissed,
  int vipHandled = 0,
  int vipMissed = 0,
  int obstaclesTapped = 0,
  int longestCombo = 0,
}) {
  final base =
      passengersHandled * 100 +
      vipHandled * 300 -
      passengersMissed * 50 -
      vipMissed * 150 -
      obstaclesTapped * 80;

  final comboBonus = calculateComboBonus(longestCombo);

  final score = base + comboBonus;
  return score < 0 ? 0 : score;
}

/// 最長コンボ数に応じたボーナス点。5コンボごとに段階的に増加する。
int calculateComboBonus(int longestCombo) {
  if (longestCombo <= 0) return 0;
  final tier = longestCombo ~/ 5;
  return tier * 50;
}

/// 経過秒数に応じたスポーン間隔(秒)。rampDurationSeconds かけて
/// baseIntervalSeconds から minIntervalSeconds まで線形に短くなり、
/// それ以降は下限に固定される。
double calculateSpawnInterval({
  required double elapsedSeconds,
  required double baseIntervalSeconds,
  required double minIntervalSeconds,
  double rampDurationSeconds = 30,
}) {
  final progress = (elapsedSeconds / rampDurationSeconds).clamp(0.0, 1.0);
  final interval =
      baseIntervalSeconds -
      (baseIntervalSeconds - minIntervalSeconds) * progress;
  return interval < minIntervalSeconds ? minIntervalSeconds : interval;
}
