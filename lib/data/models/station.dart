import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum DevelopmentType { none, onsen, shogyo, kanko }

DevelopmentType developmentTypeFromString(String? value) {
  switch (value) {
    case 'onsen':
      return DevelopmentType.onsen;
    case 'shogyo':
      return DevelopmentType.shogyo;
    case 'kanko':
      return DevelopmentType.kanko;
    default:
      return DevelopmentType.none;
  }
}

String developmentTypeToString(DevelopmentType type) {
  switch (type) {
    case DevelopmentType.onsen:
      return 'onsen';
    case DevelopmentType.shogyo:
      return 'shogyo';
    case DevelopmentType.kanko:
      return 'kanko';
    case DevelopmentType.none:
      return 'none';
  }
}

class GeoPoint2D extends Equatable {
  final double lat;
  final double lng;

  const GeoPoint2D({required this.lat, required this.lng});

  factory GeoPoint2D.fromJson(Map<String, dynamic> json) {
    return GeoPoint2D(
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  @override
  List<Object?> get props => [lat, lng];
}

class Station extends Equatable {
  final String stationID;
  final String railroadID;
  final String name;
  final GeoPoint2D position;
  final int level;
  final int revenue;
  final int passengersPerDay;
  final int appealScore;
  final DevelopmentType developmentType;
  final String? visualAssetID;
  final DateTime lastUpdated;

  const Station({
    required this.stationID,
    required this.railroadID,
    required this.name,
    required this.position,
    required this.level,
    required this.revenue,
    required this.passengersPerDay,
    required this.appealScore,
    required this.developmentType,
    required this.visualAssetID,
    required this.lastUpdated,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      stationID: json['stationID'] as String? ?? '',
      railroadID: json['railroadID'] as String? ?? '',
      name: json['name'] as String? ?? '',
      position: json['position'] != null
          ? GeoPoint2D.fromJson(json['position'] as Map<String, dynamic>)
          : const GeoPoint2D(lat: 0, lng: 0),
      level: json['level'] as int? ?? 1,
      revenue: json['revenue'] as int? ?? 0,
      passengersPerDay: json['passengersPerDay'] as int? ?? 0,
      appealScore: json['appealScore'] as int? ?? 0,
      developmentType: developmentTypeFromString(
        json['developmentType'] as String?,
      ),
      visualAssetID: json['visualAssetID'] as String?,
      // 欠損時はDateTime.now()にすると取得の度に値が変わり、履歴ソートが
      // 毎回不安定になる。決定的な値(エポック)にして「最古」扱いにする。
      lastUpdated:
          (json['lastUpdated'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stationID': stationID,
      'railroadID': railroadID,
      'name': name,
      'position': position.toJson(),
      'level': level,
      'revenue': revenue,
      'passengersPerDay': passengersPerDay,
      'appealScore': appealScore,
      'developmentType': developmentTypeToString(developmentType),
      'visualAssetID': visualAssetID,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  Station copyWith({
    int? level,
    int? revenue,
    int? passengersPerDay,
    int? appealScore,
    DevelopmentType? developmentType,
    String? visualAssetID,
    DateTime? lastUpdated,
  }) {
    return Station(
      stationID: stationID,
      railroadID: railroadID,
      name: name,
      position: position,
      level: level ?? this.level,
      revenue: revenue ?? this.revenue,
      passengersPerDay: passengersPerDay ?? this.passengersPerDay,
      appealScore: appealScore ?? this.appealScore,
      developmentType: developmentType ?? this.developmentType,
      visualAssetID: visualAssetID ?? this.visualAssetID,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
    stationID,
    railroadID,
    name,
    position,
    level,
    revenue,
    passengersPerDay,
    appealScore,
    developmentType,
    visualAssetID,
    lastUpdated,
  ];
}
