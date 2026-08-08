import 'package:equatable/equatable.dart';

class TeamFormation extends Equatable {
  final String teamID;
  final String stationID;
  final String staffID1;
  final String staffID2;
  final double compatibilityBonus;
  final double totalEfficiency;

  const TeamFormation({
    required this.teamID,
    required this.stationID,
    required this.staffID1,
    required this.staffID2,
    required this.compatibilityBonus,
    required this.totalEfficiency,
  });

  factory TeamFormation.fromJson(Map<String, dynamic> json) {
    return TeamFormation(
      teamID: json['teamID'] as String,
      stationID: json['stationID'] as String? ?? '',
      staffID1: json['staffID1'] as String? ?? '',
      staffID2: json['staffID2'] as String? ?? '',
      compatibilityBonus: (json['compatibilityBonus'] as num?)?.toDouble() ?? 1.0,
      totalEfficiency: (json['totalEfficiency'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamID': teamID,
      'stationID': stationID,
      'staffID1': staffID1,
      'staffID2': staffID2,
      'compatibilityBonus': compatibilityBonus,
      'totalEfficiency': totalEfficiency,
    };
  }

  @override
  List<Object?> get props => [
    teamID,
    stationID,
    staffID1,
    staffID2,
    compatibilityBonus,
    totalEfficiency,
  ];
}
