import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PvPRanking extends Equatable {
  final String rankingID;
  final String userID;
  final int appealScore;
  final int rank;
  final int weeklyBattles;
  final int weeklyWins;
  final DateTime lastUpdated;

  const PvPRanking({
    required this.rankingID,
    required this.userID,
    required this.appealScore,
    required this.rank,
    required this.weeklyBattles,
    required this.weeklyWins,
    required this.lastUpdated,
  });

  factory PvPRanking.fromJson(Map<String, dynamic> json) {
    return PvPRanking(
      rankingID: json['rankingID'] as String? ?? '',
      userID: json['userID'] as String? ?? '',
      appealScore: json['appealScore'] as int? ?? 0,
      rank: json['rank'] as int? ?? 0,
      weeklyBattles: json['weeklyBattles'] as int? ?? 0,
      weeklyWins: json['weeklywins'] as int? ?? json['weeklyWins'] as int? ?? 0,
      // 欠損時はDateTime.now()にせず決定的な値にフォールバックする（station.dartと同じ理由）。
      lastUpdated:
          (json['lastUpdated'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rankingID': rankingID,
      'userID': userID,
      'appealScore': appealScore,
      'rank': rank,
      'weeklyBattles': weeklyBattles,
      'weeklywins': weeklyWins,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  @override
  List<Object?> get props => [
    rankingID,
    userID,
    appealScore,
    rank,
    weeklyBattles,
    weeklyWins,
    lastUpdated,
  ];
}
