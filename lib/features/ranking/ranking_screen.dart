import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/game_logic/battle_calculator.dart';
import '../../data/models/pvp_ranking.dart';
import '../../providers/service_providers.dart';
import '../../providers/station_providers.dart';
import '../../providers/user_providers.dart';

/// 魅力度PvPランキング画面（設計書§5-6）。全国TOP100と自分の順位、
/// バトルリクエスト機能を表示する。
class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  Future<void> _requestBattle(
    BuildContext context,
    WidgetRef ref,
    PvPRanking myRanking,
    PvPRanking opponent,
  ) async {
    // PvPバトル判定（設計書§6 POST /pvp/battle-request相当）。
    // Cloud Functions未実装のためローカルスタブで判定する。
    final result = calculateBattleResult(
      challengerAppealScore: myRanking.appealScore,
      defenderAppealScore: opponent.appealScore,
    );

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('battle_result_dialog'),
        title: Text(result.challengerWon ? '勝利！' : '敗北...'),
        content: Text(
          result.challengerWon
              ? '${opponent.userID}に勝利しました！報酬 ${result.winnerReward}'
              : '${opponent.userID}に敗れました。報酬 ${result.loserReward}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result.challengerWon && context.mounted) {
      await ref
          .read(analyticsServiceProvider)
          .logBattleWon(opponentUserID: opponent.userID)
          .catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingsAsync = ref.watch(topRankingsProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final myUserID = userProfileAsync.value?.userID;

    return Scaffold(
      appBar: AppBar(title: const Text('魅力度ランキング')),
      body: rankingsAsync.when(
        data: (rankings) {
          if (rankings.isEmpty) {
            return const Center(child: Text('まだランキングデータがありません'));
          }
          final myMatches = rankings.where((r) => r.userID == myUserID);
          final myRanking = myMatches.isEmpty ? null : myMatches.first;

          return ListView.builder(
            key: const Key('ranking_list'),
            itemCount: rankings.length,
            itemBuilder: (context, index) {
              final ranking = rankings[index];
              final isMe = ranking.userID == myUserID;
              return _RankingTile(
                ranking: ranking,
                isMe: isMe,
                onBattle: isMe || myRanking == null
                    ? null
                    : () => _requestBattle(context, ref, myRanking, ranking),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('読み込みエラー: $error')),
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  final PvPRanking ranking;
  final bool isMe;
  final VoidCallback? onBattle;

  const _RankingTile({
    required this.ranking,
    required this.isMe,
    required this.onBattle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('ranking_tile_${ranking.userID}'),
      color: isMe
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4)
          : null,
      child: ListTile(
        leading: CircleAvatar(child: Text('${ranking.rank}')),
        title: Text(ranking.userID),
        subtitle: Text('週間 ${ranking.weeklyWins}勝 / ${ranking.weeklyBattles}戦'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '魅力度 ${ranking.appealScore}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (onBattle != null)
              IconButton(
                key: Key('battle_button_${ranking.userID}'),
                icon: const Icon(Icons.sports_kabaddi),
                tooltip: 'バトルを申し込む',
                onPressed: onBattle,
              ),
          ],
        ),
      ),
    );
  }
}
