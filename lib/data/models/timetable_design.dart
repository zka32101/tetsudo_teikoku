import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrainSchedule extends Equatable {
  final String trainID;
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final List<String> stops;

  const TrainSchedule({
    required this.trainID,
    required this.startTime,
    required this.endTime,
    required this.stops,
  });

  factory TrainSchedule.fromJson(Map<String, dynamic> json) {
    return TrainSchedule(
      trainID: json['trainID'] as String,
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      stops: (json['stops'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'trainID': trainID,
    'startTime': startTime,
    'endTime': endTime,
    'stops': stops,
  };

  @override
  List<Object?> get props => [trainID, startTime, endTime, stops];
}

class TimetableDesign extends Equatable {
  final String timetableID;
  final String userID;
  final String railroadID;
  final List<TrainSchedule> trains;
  final double efficiencyScore;
  final DateTime createdAt;

  const TimetableDesign({
    required this.timetableID,
    required this.userID,
    required this.railroadID,
    required this.trains,
    required this.efficiencyScore,
    required this.createdAt,
  });

  factory TimetableDesign.fromJson(Map<String, dynamic> json) {
    return TimetableDesign(
      timetableID: json['timetableID'] as String,
      userID: json['userID'] as String? ?? '',
      railroadID: json['railroadID'] as String? ?? '',
      trains: (json['trains'] as List<dynamic>? ?? [])
          .map((e) => TrainSchedule.fromJson(e as Map<String, dynamic>))
          .toList(),
      efficiencyScore: (json['efficiencyScore'] as num?)?.toDouble() ?? 0.0,
      // 欠損時はDateTime.now()にせず決定的な値にフォールバックする（station.dartと同じ理由）。
      createdAt:
          (json['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timetableID': timetableID,
      'userID': userID,
      'railroadID': railroadID,
      'trains': trains.map((t) => t.toJson()).toList(),
      'efficiencyScore': efficiencyScore,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
    timetableID,
    userID,
    railroadID,
    trains,
    efficiencyScore,
    createdAt,
  ];
}
