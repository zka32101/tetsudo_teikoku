import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PassengerJourney extends Equatable {
  final String journeyID;
  final String passengerID;
  final String fromStationID;
  final String toStationID;
  final List<String> viaStations;
  final int satisfaction; // 1-5
  final int revenue;
  final DateTime timestamp;

  const PassengerJourney({
    required this.journeyID,
    required this.passengerID,
    required this.fromStationID,
    required this.toStationID,
    required this.viaStations,
    required this.satisfaction,
    required this.revenue,
    required this.timestamp,
  });

  factory PassengerJourney.fromJson(Map<String, dynamic> json) {
    return PassengerJourney(
      journeyID: json['journeyID'] as String,
      passengerID: json['passengerID'] as String? ?? '',
      fromStationID: json['fromStationID'] as String? ?? '',
      toStationID: json['toStationID'] as String? ?? '',
      viaStations: (json['viaStations'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      satisfaction: json['satisfaction'] as int? ?? 3,
      revenue: json['revenue'] as int? ?? 0,
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'journeyID': journeyID,
      'passengerID': passengerID,
      'fromStationID': fromStationID,
      'toStationID': toStationID,
      'viaStations': viaStations,
      'satisfaction': satisfaction,
      'revenue': revenue,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  @override
  List<Object?> get props => [
    journeyID,
    passengerID,
    fromStationID,
    toStationID,
    viaStations,
    satisfaction,
    revenue,
    timestamp,
  ];
}
