import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum StaffRarity { n, r, sr, ssr }

StaffRarity staffRarityFromString(String? value) {
  switch (value) {
    case 'R':
      return StaffRarity.r;
    case 'SR':
      return StaffRarity.sr;
    case 'SSR':
      return StaffRarity.ssr;
    default:
      return StaffRarity.n;
  }
}

String staffRarityToString(StaffRarity rarity) {
  switch (rarity) {
    case StaffRarity.r:
      return 'R';
    case StaffRarity.sr:
      return 'SR';
    case StaffRarity.ssr:
      return 'SSR';
    case StaffRarity.n:
      return 'N';
  }
}

class StaffStats extends Equatable {
  final int hospitality;
  final int efficiency;
  final int kindness;

  const StaffStats({
    required this.hospitality,
    required this.efficiency,
    required this.kindness,
  });

  factory StaffStats.fromJson(Map<String, dynamic> json) {
    return StaffStats(
      hospitality: json['hospitality'] as int? ?? 0,
      efficiency: json['efficiency'] as int? ?? 0,
      kindness: json['kindness'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'hospitality': hospitality,
    'efficiency': efficiency,
    'kindness': kindness,
  };

  @override
  List<Object?> get props => [hospitality, efficiency, kindness];
}

class StationStaff extends Equatable {
  final String staffID;
  final String stationID;
  final String userID;
  final String name;
  final StaffRarity rarity;
  final StaffStats stats;
  final int level;
  final int exp;
  final DateTime createdAt;

  const StationStaff({
    required this.staffID,
    required this.stationID,
    required this.userID,
    required this.name,
    required this.rarity,
    required this.stats,
    required this.level,
    required this.exp,
    required this.createdAt,
  });

  factory StationStaff.fromJson(Map<String, dynamic> json) {
    return StationStaff(
      staffID: json['staffID'] as String? ?? '',
      stationID: json['stationID'] as String? ?? '',
      userID: json['userID'] as String? ?? '',
      name: json['name'] as String? ?? '',
      rarity: staffRarityFromString(json['rarity'] as String?),
      stats: json['stats'] != null
          ? StaffStats.fromJson(json['stats'] as Map<String, dynamic>)
          : const StaffStats(hospitality: 0, efficiency: 0, kindness: 0),
      level: json['level'] as int? ?? 1,
      exp: json['exp'] as int? ?? 0,
      // 欠損時にDateTime.now()だと取得の度に値が変わり順序が不安定になるため、
      // 決定的な値(エポック)にフォールバックする（station.dartと同じ理由）。
      createdAt:
          (json['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staffID': staffID,
      'stationID': stationID,
      'userID': userID,
      'name': name,
      'rarity': staffRarityToString(rarity),
      'stats': stats.toJson(),
      'level': level,
      'exp': exp,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
    staffID,
    stationID,
    userID,
    name,
    rarity,
    stats,
    level,
    exp,
    createdAt,
  ];
}
