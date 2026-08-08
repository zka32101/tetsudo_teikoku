import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'station.dart';

class TownDevelopment extends Equatable {
  final String townID;
  final String stationID;
  final DevelopmentType developmentType;
  final int level;
  final int aesthetics;
  final int liveliness;
  final String? visualAssetID;
  final DateTime selectedAt;

  const TownDevelopment({
    required this.townID,
    required this.stationID,
    required this.developmentType,
    required this.level,
    required this.aesthetics,
    required this.liveliness,
    required this.visualAssetID,
    required this.selectedAt,
  });

  factory TownDevelopment.fromJson(Map<String, dynamic> json) {
    return TownDevelopment(
      townID: json['townID'] as String? ?? '',
      stationID: json['stationID'] as String? ?? '',
      developmentType: developmentTypeFromString(
        json['developmentType'] as String?,
      ),
      level: json['level'] as int? ?? 1,
      aesthetics: json['aesthetics'] as int? ?? 0,
      liveliness: json['liveliness'] as int? ?? 0,
      visualAssetID: json['visualAssetID'] as String?,
      selectedAt:
          (json['selectedAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'townID': townID,
      'stationID': stationID,
      'developmentType': developmentTypeToString(developmentType),
      'level': level,
      'aesthetics': aesthetics,
      'liveliness': liveliness,
      'visualAssetID': visualAssetID,
      'selectedAt': Timestamp.fromDate(selectedAt),
    };
  }

  @override
  List<Object?> get props => [
    townID,
    stationID,
    developmentType,
    level,
    aesthetics,
    liveliness,
    visualAssetID,
    selectedAt,
  ];
}
