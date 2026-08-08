import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum GameEventType { seasonal, surprise, delay }

GameEventType gameEventTypeFromString(String? value) {
  switch (value) {
    case 'surprise':
      return GameEventType.surprise;
    case 'delay':
      return GameEventType.delay;
    default:
      return GameEventType.seasonal;
  }
}

String gameEventTypeToString(GameEventType type) {
  switch (type) {
    case GameEventType.surprise:
      return 'surprise';
    case GameEventType.delay:
      return 'delay';
    case GameEventType.seasonal:
      return 'seasonal';
  }
}

class EventReward extends Equatable {
  final String rewardType;
  final int amount;

  const EventReward({required this.rewardType, required this.amount});

  factory EventReward.fromJson(Map<String, dynamic> json) {
    return EventReward(
      rewardType: json['rewardType'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'rewardType': rewardType, 'amount': amount};

  @override
  List<Object?> get props => [rewardType, amount];
}

class GameEvent extends Equatable {
  final String eventID;
  final GameEventType eventType;
  final String? stationID;
  final String description;
  final EventReward reward;
  final DateTime startTime;
  final DateTime endTime;

  const GameEvent({
    required this.eventID,
    required this.eventType,
    required this.stationID,
    required this.description,
    required this.reward,
    required this.startTime,
    required this.endTime,
  });

  factory GameEvent.fromJson(Map<String, dynamic> json) {
    return GameEvent(
      eventID: json['eventID'] as String? ?? '',
      eventType: gameEventTypeFromString(json['eventType'] as String?),
      stationID: json['stationID'] as String?,
      description: json['description'] as String? ?? '',
      reward: json['reward'] != null
          ? EventReward.fromJson(json['reward'] as Map<String, dynamic>)
          : const EventReward(rewardType: '', amount: 0),
      startTime: (json['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (json['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventID': eventID,
      'eventType': gameEventTypeToString(eventType),
      'stationID': stationID,
      'description': description,
      'reward': reward.toJson(),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
    };
  }

  @override
  List<Object?> get props => [
    eventID,
    eventType,
    stationID,
    description,
    reward,
    startTime,
    endTime,
  ];
}
