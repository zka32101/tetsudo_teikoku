import 'package:equatable/equatable.dart';

class Railroad extends Equatable {
  final String railroadID;
  final String name;
  final String startStation;
  final String endStation;
  final int totalStations;
  final List<String> stations;

  const Railroad({
    required this.railroadID,
    required this.name,
    required this.startStation,
    required this.endStation,
    required this.totalStations,
    required this.stations,
  });

  factory Railroad.fromJson(Map<String, dynamic> json) {
    return Railroad(
      railroadID: json['railroadID'] as String,
      name: json['name'] as String? ?? '',
      startStation: json['startStation'] as String? ?? '',
      endStation: json['endStation'] as String? ?? '',
      totalStations: json['totalStations'] as int? ?? 0,
      stations: (json['stations'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'railroadID': railroadID,
      'name': name,
      'startStation': startStation,
      'endStation': endStation,
      'totalStations': totalStations,
      'stations': stations,
    };
  }

  @override
  List<Object?> get props => [
    railroadID,
    name,
    startStation,
    endStation,
    totalStations,
    stations,
  ];
}
