import 'package:flutter_test/flutter_test.dart';
import 'package:tetsudo_teikoku/core/game_logic/timetable_efficiency_calculator.dart';
import 'package:tetsudo_teikoku/data/models/timetable_design.dart';

TimetableDesign _timetable(List<TrainSchedule> trains) {
  return TimetableDesign(
    timetableID: 't1',
    userID: 'u1',
    railroadID: 'r1',
    trains: trains,
    efficiencyScore: 0,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('calculateEfficiencyScore', () {
    test('empty timetable scores 0', () {
      expect(calculateEfficiencyScore(_timetable([])), 0);
    });

    test('perfectly even intervals score higher regularity than clustered ones', () {
      final even = _timetable([
        TrainSchedule(trainID: '1', startTime: '08:00', endTime: '08:30', stops: ['a', 'b']),
        TrainSchedule(trainID: '2', startTime: '08:20', endTime: '08:50', stops: ['a', 'b']),
        TrainSchedule(trainID: '3', startTime: '08:40', endTime: '09:10', stops: ['a', 'b']),
      ]);
      final clustered = _timetable([
        TrainSchedule(trainID: '1', startTime: '08:00', endTime: '08:30', stops: ['a', 'b']),
        TrainSchedule(trainID: '2', startTime: '08:05', endTime: '08:35', stops: ['a', 'b']),
        TrainSchedule(trainID: '3', startTime: '09:30', endTime: '10:00', stops: ['a', 'b']),
      ]);

      expect(calculateEfficiencyScore(even), greaterThan(calculateEfficiencyScore(clustered)));
    });

    test('more stops per train increases the score', () {
      final fewStops = _timetable([
        TrainSchedule(trainID: '1', startTime: '08:00', endTime: '08:30', stops: ['a']),
      ]);
      final manyStops = _timetable([
        TrainSchedule(
          trainID: '1',
          startTime: '08:00',
          endTime: '08:30',
          stops: List.generate(10, (i) => 'stop$i'),
        ),
      ]);

      expect(calculateEfficiencyScore(manyStops), greaterThan(calculateEfficiencyScore(fewStops)));
    });

    test('a single gap (2 trains) never scores a perfect 100 regardless of spacing', () {
      final wildlyUneven = _timetable([
        TrainSchedule(trainID: '1', startTime: '08:00', endTime: '08:30', stops: ['a', 'b']),
        TrainSchedule(trainID: '2', startTime: '13:00', endTime: '13:30', stops: ['a', 'b']),
      ]);

      expect(calculateEfficiencyScore(wildlyUneven), lessThan(100));
    });

    test('score is always within 0-100', () {
      final timetable = _timetable([
        TrainSchedule(trainID: '1', startTime: '08:00', endTime: '08:30', stops: List.generate(20, (i) => 's$i')),
        TrainSchedule(trainID: '2', startTime: '08:00', endTime: '08:30', stops: []),
      ]);
      final score = calculateEfficiencyScore(timetable);
      expect(score, inInclusiveRange(0, 100));
    });
  });
}
