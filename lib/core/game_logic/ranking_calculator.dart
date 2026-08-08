import 'package:equatable/equatable.dart';

class RankedUser extends Equatable {
  final String userID;
  final int rank;

  const RankedUser({required this.userID, required this.rank});

  @override
  List<Object?> get props => [userID, rank];
}

/// appealScore の高い順に順位を付ける。
/// 同点の場合は同順位とし、次の順位は人数分スキップする（1224方式）。
/// 例: [100,100,90] → [1,1,3]
List<RankedUser> calculateRanking(Map<String, int> userAppealScores) {
  final entries = userAppealScores.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final results = <RankedUser>[];
  int rank = 0;
  int previousScore = -1;
  int position = 0;

  for (final entry in entries) {
    position++;
    if (entry.value != previousScore) {
      rank = position;
      previousScore = entry.value;
    }
    results.add(RankedUser(userID: entry.key, rank: rank));
  }

  return results;
}
