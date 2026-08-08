import 'package:equatable/equatable.dart';

class BattleResult extends Equatable {
  final bool challengerWon;
  final int winnerReward;
  final int loserReward;

  const BattleResult({
    required this.challengerWon,
    required this.winnerReward,
    required this.loserReward,
  });

  @override
  List<Object?> get props => [challengerWon, winnerReward, loserReward];
}

/// PvPバトルの勝敗判定（設計書§6 POST /pvp/battle-request相当）。
/// Cloud Functions未実装のため、判定自体はクライアント側のローカルスタブで行う。
/// 魅力度スコアが高い方が勝利。同点の場合は防衛側（defender）が勝つ（ホームアドバンテージ）。
BattleResult calculateBattleResult({
  required int challengerAppealScore,
  required int defenderAppealScore,
}) {
  final challengerWon = challengerAppealScore > defenderAppealScore;
  return BattleResult(
    challengerWon: challengerWon,
    winnerReward: 100,
    loserReward: 20,
  );
}
