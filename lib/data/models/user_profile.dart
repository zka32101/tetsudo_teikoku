import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile extends Equatable {
  final String userID;
  final String name;
  final int level;
  final int totalMoney;
  final int currentMoney;
  final int appealScore;
  final int rank;
  final DateTime lastLogin;
  final DateTime createdAt;

  const UserProfile({
    required this.userID,
    required this.name,
    required this.level,
    required this.totalMoney,
    required this.currentMoney,
    required this.appealScore,
    required this.rank,
    required this.lastLogin,
    required this.createdAt,
  });

  factory UserProfile.initial({required String userID, required String name}) {
    final now = DateTime.now();
    return UserProfile(
      userID: userID,
      name: name,
      level: 1,
      totalMoney: 0,
      currentMoney: 0,
      appealScore: 0,
      rank: 0,
      lastLogin: now,
      createdAt: now,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userID: json['userID'] as String,
      name: json['name'] as String? ?? '',
      level: json['level'] as int? ?? 1,
      totalMoney: json['totalMoney'] as int? ?? 0,
      currentMoney: json['currentMoney'] as int? ?? 0,
      appealScore: json['appealScore'] as int? ?? 0,
      rank: json['rank'] as int? ?? 0,
      lastLogin: (json['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'name': name,
      'level': level,
      'totalMoney': totalMoney,
      'currentMoney': currentMoney,
      'appealScore': appealScore,
      'rank': rank,
      'lastLogin': Timestamp.fromDate(lastLogin),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserProfile copyWith({
    String? name,
    int? level,
    int? totalMoney,
    int? currentMoney,
    int? appealScore,
    int? rank,
    DateTime? lastLogin,
  }) {
    return UserProfile(
      userID: userID,
      name: name ?? this.name,
      level: level ?? this.level,
      totalMoney: totalMoney ?? this.totalMoney,
      currentMoney: currentMoney ?? this.currentMoney,
      appealScore: appealScore ?? this.appealScore,
      rank: rank ?? this.rank,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    userID,
    name,
    level,
    totalMoney,
    currentMoney,
    appealScore,
    rank,
    lastLogin,
    createdAt,
  ];
}
